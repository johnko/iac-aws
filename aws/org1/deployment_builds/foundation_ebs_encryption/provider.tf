# Provider configurations for multi-region EBS encryption

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
