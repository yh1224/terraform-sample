terraform {
  required_version = ">= 0.11.0"

  #backend "s3" {
  #  bucket = "terraform"
  #  key    = "terraform.tfstate.aws"
  #  region = "ap-northeast-1"
  #}
}

# Specify the provider and access details
provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

# IAM Role (EC2)
resource "aws_iam_role" "role_ec2" {
  name = "${var.service}-role-ec2"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name      = "${var.service}-role-ec2"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }
}

resource "aws_iam_role_policy_attachment" "role_policy_attach_ec2" {
  role       = "${aws_iam_role.role_ec2.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "role_policy_ec2" {
  name = "${var.service}-role-policy-ec2"
  role = "${aws_iam_role.role_ec2.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::${aws_s3_bucket.s3.bucket}/*"
    }
  ]
}
EOF
}

# Security Group (EC2)
resource "aws_security_group" "sg_ec2" {
  name        = "${var.service}-sg-ec2"
  description = "EC2"
  vpc_id      = "${aws_vpc.vpc.id}"

  tags = {
    Name      = "${var.service}-ec2"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  # HTTP access from Load Balancer
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.sg_lb.id}"]
    description     = "Load Balancer"
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = ""
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = ""
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Security Group (Load Balancer)
resource "aws_security_group" "sg_lb" {
  name        = "${var.service}-sg-lb"
  description = "Load Balancer"
  vpc_id      = "${aws_vpc.vpc.id}"

  tags = {
    Name      = "${var.service}-lb"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }

  # HTTP (test)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Key pair
resource "aws_key_pair" "keypair" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

# EC2
resource "aws_instance" "ec2" {
  ami                    = "${var.ec2_ami}"
  instance_type          = "${var.ec2_instance_type}"
  key_name               = "${var.key_name}"
  availability_zone      = "ap-northeast-1a"
  subnet_id              = "${aws_subnet.subnet_public_a.id}"
  vpc_security_group_ids = ["${aws_security_group.sg_ec2.id}"]

  tags = {
    Name      = "${var.service}-ec2"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }
}

# Load Balancing
resource "aws_iam_instance_profile" "iam_profile_ec2" {
  name = "${var.service}-iam-profile-ec2"
  role = "${aws_iam_role.role_ec2.name}"
}

#resource "aws_launch_configuration" "lc" {
#  name_prefix          = "${var.service}-lc"
#  image_id             = "${var.ec2_ami}"
#  instance_type        = "t3.micro"
#  iam_instance_profile = "${aws_iam_instance_profile.iam_profile_ec2.name}"
#  key_name             = "${var.key_name}"
#  security_groups      = ["${aws_security_group.sg_ec2.id}"]
#}

resource "aws_lb_target_group" "tg" {
  name     = "${var.service}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.vpc.id}"

  health_check {
    protocol            = "HTTP"
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200,302,401"
  }

  tags = {
    Name      = "${var.service}-tg"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }
}

#resource "aws_autoscaling_group" "asg" {
#  name                 = "${var.service}-asg"
#  max_size             = 1
#  min_size             = 1
#  launch_configuration = "${aws_launch_configuration.lc.name}"
#  target_group_arns    = ["${aws_lb_target_group.tg.arn}"]
#
#  vpc_zone_identifier = [
#    "${aws_subnet.subnet_public_a.id}",
#    "${aws_subnet.subnet_public_c.id}",
#    "${aws_subnet.subnet_public_d.id}",
#  ]
#
#  tags = [
#    {
#      key                 = "CreatedBy"
#      value               = "${var.created_by}"
#      propagate_at_launch = true
#    },
#    {
#      key                 = "Name"
#      value               = "${var.service}-ec2"
#      propagate_at_launch = true
#    },
#    {
#      key                 = "Service"
#      value               = "${var.service}"
#      propagate_at_launch = true
#    },
#    {
#      key                 = "Env"
#      value               = "${var.env}"
#      propagate_at_launch = true
#    },
#  ]
#}

resource "aws_lb" "lb" {
  name            = "${var.service}-lb"
  security_groups = ["${aws_security_group.sg_lb.id}"]

  subnets = [
    "${aws_subnet.subnet_public_a.id}",
    "${aws_subnet.subnet_public_c.id}",
    "${aws_subnet.subnet_public_d.id}",
  ]

  tags = {
    Name      = "${var.service}-lb"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = "${aws_lb.lb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.tg.arn}"
  }
}
