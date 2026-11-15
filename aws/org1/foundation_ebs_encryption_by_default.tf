# EBS Encryption by Default
# Enables encryption across all governed regions
# Uses the region argument (supported in AWS provider 6.71.0+)

resource "aws_ebs_encryption_by_default" "ca_central_1" {
  enabled = true
}

resource "aws_ebs_encryption_by_default" "ca_west_1" {
  region  = "ca-west-1"
  enabled = true
}

resource "aws_ebs_encryption_by_default" "us_east_1" {
  region  = "us-east-1"
  enabled = true
}

resource "aws_ebs_encryption_by_default" "us_east_2" {
  region  = "us-east-2"
  enabled = true
}

resource "aws_ebs_encryption_by_default" "us_west_2" {
  region  = "us-west-2"
  enabled = true
}
