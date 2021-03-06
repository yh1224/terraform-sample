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
  region  = var.aws_region
  profile = var.aws_profile
}

# Resource group
resource "aws_resourcegroups_group" "rg" {
  name = "${var.service}-group"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [
    "AWS::AllSupported"
  ],
  "TagFilters": [
    {
      "Key": "Service",
      "Values": ["${var.service}"]
    }
  ]
}
JSON
  }
}
