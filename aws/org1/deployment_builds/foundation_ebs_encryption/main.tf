# EBS Encryption by Default - Multi-region Configuration

resource "aws_ebs_encryption_by_default" "ca_central_1" {
  enabled = true
}

resource "aws_ebs_encryption_by_default" "ca_west_1" {
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
