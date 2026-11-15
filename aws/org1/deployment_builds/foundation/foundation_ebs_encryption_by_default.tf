# EBS Encryption by Default
# Uses modules/ebs-encryption-by-default/ to enable encryption across all governed regions

provider "aws" {
  alias  = "ca_west"
  region = "ca-west-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us_east_2"
  region = "us-east-2"
}

provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"
}

module "ebs_encryption" {
  source = "../../../../modules/ebs-encryption-by-default"

  providers = {
    aws           = aws
    aws.ca_west   = aws.ca_west
    aws.us_east_1 = aws.us_east_1
    aws.us_east_2 = aws.us_east_2
    aws.us_west_2 = aws.us_west_2
  }
}
