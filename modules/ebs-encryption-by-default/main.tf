# EBS Encryption by Default - Multi-region Module
# This module enables EBS encryption by default across multiple regions

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [
        aws,
        aws.ca_west,
        aws.us_east_1,
        aws.us_east_2,
        aws.us_west_2,
      ]
    }
  }
}

resource "aws_ebs_encryption_by_default" "this" {
  enabled = true
}

resource "aws_ebs_encryption_by_default" "ca_west" {
  provider = aws.ca_west
  enabled  = true
}

resource "aws_ebs_encryption_by_default" "us_east_1" {
  provider = aws.us_east_1
  enabled  = true
}

resource "aws_ebs_encryption_by_default" "us_east_2" {
  provider = aws.us_east_2
  enabled  = true
}

resource "aws_ebs_encryption_by_default" "us_west_2" {
  provider = aws.us_west_2
  enabled  = true
}
