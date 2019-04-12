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

# Security Group (EC2)
resource "aws_security_group" "sg_ec2" {
  name        = "${var.service}-sg-ec2"
  description = "EC2"

  tags {
    Name      = "${var.service}-ec2"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CraetedBy = "${var.created_by}"
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
  vpc_security_group_ids = ["${aws_security_group.sg_ec2.id}"]

  tags {
    Name      = "${var.service}-ec2"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }
}
