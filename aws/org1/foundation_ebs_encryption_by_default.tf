# Enable default EBS encryption by default across all governed regions
# This ensures all new EBS volumes are automatically encrypted

locals {
  ebs_encryption_regions = {
    "ca-central-1" = {}
    "ca-west-1"    = {}
    "us-east-1"    = {}
    "us-west-2" = {
      # Check what is the cause of error
      # Region might be covered by other deployment
    }
  }
}

provider "aws" {
  alias = "ca_central"
  allowed_account_ids = [
    var.aws_account_id
  ]
  default_tags {
    tags = {
      iacdeployer = "terraform"
    }
  }
  region = "ca-central-1"
}

provider "aws" {
  alias = "ca_west"
  allowed_account_ids = [
    var.aws_account_id
  ]
  default_tags {
    tags = {
      iacdeployer = "terraform"
    }
  }
  region = "ca-west-1"
}

provider "aws" {
  alias = "us_east_1"
  allowed_account_ids = [
    var.aws_account_id
  ]
  default_tags {
    tags = {
      iacdeployer = "terraform"
    }
  }
  region = "us-east-1"
}

provider "aws" {
  alias = "us_east_2"
  allowed_account_ids = [
    var.aws_account_id
  ]
  default_tags {
    tags = {
      iacdeployer = "terraform"
    }
  }
  region = "us-east-2"
}

provider "aws" {
  alias = "us_west_2"
  allowed_account_ids = [
    var.aws_account_id
  ]
  default_tags {
    tags = {
      iacdeployer = "terraform"
    }
  }
  region = "us-west-2"
}

resource "aws_ebs_encryption_by_default" "ca_central_1" {
  provider = aws.ca_central
  enabled  = true
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
