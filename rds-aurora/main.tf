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

# Security Group (RDS)
resource "aws_security_group" "sg_rds" {
  name        = "${var.service}-sg-rds"
  description = "RDS"
  vpc_id      = "${aws_vpc.vpc.id}"

  tags {
    Name      = "${var.service}-sg-rds"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }

  # MySQL access inside VPC
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${aws_vpc.vpc.cidr_block}"]
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

# DB
resource "aws_db_subnet_group" "db_sg" {
  name        = "sg-db"
  description = "DB Subnet group"

  subnet_ids = [
    "${aws_subnet.subnet_private_a.id}",
    "${aws_subnet.subnet_private_c.id}",
    "${aws_subnet.subnet_private_d.id}",
  ]

  tags {
    Name      = "${var.service}-sg-db"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }
}

# DB
resource "aws_rds_cluster_parameter_group" "db_cluster_pg" {
  name   = "${var.service}-pg-db-cluster"
  family = "aurora-mysql5.7"

  tags {
    Name      = "${var.service}-pg-db-cluster"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }

  parameter {
    name         = "character_set_client"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_connection"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_database"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_filesystem"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_results"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_server"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "collation_connection"
    value        = "utf8mb4_general_ci"
    apply_method = "immediate"
  }

  parameter {
    name         = "collation_server"
    value        = "utf8mb4_general_ci"
    apply_method = "immediate"
  }

  parameter {
    name         = "time_zone"
    value        = "Asia/Tokyo"
    apply_method = "immediate"
  }

  tags {
    Name      = "${var.service}-pg-db-cluster"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }
}

resource "aws_rds_cluster" "db_cluster" {
  cluster_identifier = "${var.service}-db-cluster"
  engine             = "aurora-mysql"
  engine_version     = "5.7.12"
  availability_zones = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]

  tags {
    Name      = "${var.service}-db-cluster"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }

  database_name                   = "db"
  master_username                 = "user"
  master_password                 = "password"
  backup_retention_period         = 5
  preferred_backup_window         = "07:00-09:00"
  final_snapshot_identifier       = "${var.service}-final"
  skip_final_snapshot             = true
  vpc_security_group_ids          = ["${aws_security_group.sg_rds.id}"]
  db_subnet_group_name            = "${aws_db_subnet_group.db_sg.name}"
  db_cluster_parameter_group_name = "${aws_rds_cluster_parameter_group.db_cluster_pg.name}"
}

resource "aws_db_parameter_group" "db_pg" {
  name   = "${var.service}-db-pg"
  family = "aurora-mysql5.7"

  tags {
    Name      = "${var.service}-pg-db"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }
}

resource "aws_rds_cluster_instance" "db" {
  count                   = 1
  identifier              = "${var.service}-db-${count.index}"
  cluster_identifier      = "${aws_rds_cluster.db_cluster.id}"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.12"
  instance_class          = "db.t3.small"
  db_subnet_group_name    = "${aws_db_subnet_group.db_sg.name}"
  db_parameter_group_name = "${aws_db_parameter_group.db_pg.name}"

  tags {
    Name      = "${var.service}-db"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }
}

#resource "aws_db_instance" "db_test" {
#  identifier             = "db"
#  allocated_storage      = "20"
#  engine                 = "mysql"
#  instance_class         = "db.t3.micro"
#  name                   = "db"
#  username               = "user"
#  password               = "password"
#  db_subnet_group_name   = "${aws_db_subnet_group.db_sg.name}"
#  vpc_security_group_ids = ["${aws_security_group.sg_rds.id}"]
#
#  tags {
#    Name = "${var.service}-db"
#    Service = "${var.service}"
#    Env = "${var.env}"
#    CreatedBy = "${var.created_by}"
#  }
#}
