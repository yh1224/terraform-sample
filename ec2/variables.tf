variable "created_by" {
  description = "Resource creator"
}

variable "aws_region" {
  description = "AWS region"
  default     = "ap-northeast-1"
}

variable "aws_profile" {
  description = "AWS profile"
  default     = "default"
}

variable "service" {
  description = "Service name"
}

variable "env" {
  description = "Environment name"
  default     = "development"
}

variable "key_name" {
  description = "Key pair name"
}

variable "public_key_path" {
  description = "Path to public key file"
  default     = "~/.ssh/id_rsa.pub"
}

variable "ec2_instance_type" {
  description = "Instance type for EC2"
  default     = "t2.micro"
}

variable "ec2_ami" {
  description = "AMI for EC2"
}
