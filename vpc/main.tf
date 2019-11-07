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

# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.11.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name      = "${var.service}-vpc"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name      = "${var.service}-igw"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }
}

# Route (for public)
resource "aws_default_route_table" "rt_default" {
  default_route_table_id = "${aws_vpc.vpc.main_route_table_id}"

  tags = {
    Name      = "${var.service}-rt-default"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }
}

resource "aws_route_table" "rt_public" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name      = "${var.service}-rt-public"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }
}

resource "aws_route" "route_internet" {
  #route_table_id         = "${aws_vpc.vpc.main_route_table_id}"
  route_table_id         = "${aws_route_table.rt_public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

# Subnets
resource "aws_subnet" "subnet_public_a" {
  availability_zone       = "ap-northeast-1a"
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.11.11.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.service}-subnet-public-a"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }
}

resource "aws_route_table_association" "rta_public_a" {
  subnet_id      = "${aws_subnet.subnet_public_a.id}"
  route_table_id = "${aws_route_table.rt_public.id}"
}

resource "aws_subnet" "subnet_public_c" {
  availability_zone       = "ap-northeast-1c"
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.11.21.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.service}-subnet-public-c"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }
}

resource "aws_route_table_association" "rta_public_c" {
  subnet_id      = "${aws_subnet.subnet_public_c.id}"
  route_table_id = "${aws_route_table.rt_public.id}"
}

resource "aws_subnet" "subnet_public_d" {
  availability_zone       = "ap-northeast-1d"
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.11.31.0/24"
  map_public_ip_on_launch = true

  tags = {
    CreatedBy = "${var.created_by}"
    Name      = "${var.service}-subnet-public-d"
    Service   = "${var.service}"
    Env       = "${var.env}"
  }
}

resource "aws_route_table_association" "rta_public_d" {
  subnet_id      = "${aws_subnet.subnet_public_d.id}"
  route_table_id = "${aws_route_table.rt_public.id}"
}

resource "aws_subnet" "subnet_private_a" {
  availability_zone       = "ap-northeast-1a"
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.11.12.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.service}-subnet-private-a"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }
}

resource "aws_subnet" "subnet_private_c" {
  availability_zone       = "ap-northeast-1c"
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.11.22.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.service}-subnet-private-c"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }
}

resource "aws_subnet" "subnet_private_d" {
  availability_zone       = "ap-northeast-1d"
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.11.32.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.service}-subnet-private-d"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }
}
