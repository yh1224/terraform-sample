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
