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

  primary_region   = "ca-central-1"
  secondary_region = "us-east-2"

  codebuild_types = {
    container-linux-small = {
      build_timeout   = 60
      compute_type    = "BUILD_GENERAL1_SMALL"
      image           = "aws/codebuild/standard:7.0"
      privileged_mode = true
      queued_timeout  = 90
      region          = local.primary_region
      type            = "LINUX_CONTAINER"
    }
    lambda-linux-1 = {
      build_timeout   = 15
      compute_type    = "BUILD_LAMBDA_1GB"
      image           = "aws/codebuild/amazonlinux-x86_64-lambda-standard:python3.13"
      privileged_mode = false
      queued_timeout  = null
      region          = local.secondary_region
      type            = "LINUX_LAMBDA_CONTAINER"
    }
  }

  slack_user_roles = {
    "viewer"   = {}
    "approver" = {}
    "invoker"  = {}
  }
}

data "aws_caller_identity" "current" {}
