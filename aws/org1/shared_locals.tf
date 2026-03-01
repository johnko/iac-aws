locals {
  governedRegions = [ # List of regions to govern
    ##### ORDER MATTERS TO PREVENT CHANGE
    "ca-central-1",
    "us-east-2", # bedrock cross-region inference profile
    "us-east-1",
    "ca-west-1",
    "us-west-2", # bedrock cross-region inference profile
  ]

  unusedRegions = [
    "ap-northeast-1",
    "ap-northeast-2",
    "ap-northeast-3",
    "ap-south-1",
    "ap-southeast-1",
    "ap-southeast-2",
    "eu-central-1",
    "eu-north-1",
    "eu-west-1",
    "eu-west-2",
    "eu-west-3",
    "sa-east-1",
    "us-west-1",
  ]
}

data "aws_caller_identity" "current" {}
