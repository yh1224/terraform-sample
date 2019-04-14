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

# Origin Access Identity (CloudFront to S3)
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "Origin Access Identity"
}

# S3
resource "aws_s3_bucket" "s3" {
  #provider = "aws.prod"
  bucket = "${var.bucket_name}"
  acl    = "private"

  tags {
    Name      = "${var.service}-s3"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }

  cors_rule {
    allowed_headers = ["Authorization"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }

  #policy = <<POLICY
  #{
  #  "Version": "2008-10-17",
  #  "Id": "PolicyForCloudFrontPrivateContent",
  #  "Statement": [
  #    {
  #      "Sid": "1",
  #      "Effect": "Allow",
  #      "Principal": {
  #        "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E15QHX7M59J1S0"
  #      },
  #      "Action": "s3:GetObject",
  #      "Resource": "arn:aws:s3:::${aws_s3_bucket.s3.bucket}/*"
  #    }
  #  ]
  #}
  #POLICY
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.s3.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.oai.iam_arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = "${aws_s3_bucket.s3.id}"
  policy = "${data.aws_iam_policy_document.s3_policy.json}"
}

# CloudFront
resource "aws_cloudfront_distribution" "cf_s3" {
  comment = "S3 Distribution"

  tags {
    Name      = "${var.service}-cf-s3"
    Service   = "${var.service}"
    Env       = "${var.env}"
    CreatedBy = "${var.created_by}"
  }

  origin {
    domain_name = "${aws_s3_bucket.s3.bucket_regional_domain_name}"
    origin_id   = "S3-${aws_s3_bucket.s3.bucket}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path}"
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.s3.bucket}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    trusted_signers        = ["self"]
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
