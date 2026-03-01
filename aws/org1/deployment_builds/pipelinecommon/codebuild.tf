locals {
  codebuild_types = {
    container-linux-small = {
      compute_type    = "BUILD_GENERAL1_SMALL"
      image           = "aws/codebuild/standard:7.0"
      privileged_mode = true
      region          = local.primary_region
      type            = "LINUX_CONTAINER"
    }
    lambda-linux-1 = {
      compute_type    = "BUILD_LAMBDA_1GB"
      image           = "aws/codebuild/amazonlinux-x86_64-lambda-standard:python3.13"
      privileged_mode = false
      region          = local.secondary_region
      type            = "LINUX_LAMBDA_CONTAINER"
    }
  }
}

resource "aws_iam_role" "terraform_plan" {
  name = "CodeBuildRole-TerraformPlan"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "codebuild.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

}

resource "aws_codebuild_project" "terraform_plan" {
  for_each = local.codebuild_types

  region = each.value.region

  name         = "TerraformPlan-${each.key}"
  service_role = aws_iam_role.terraform_plan.arn

  build_timeout  = 60
  queued_timeout = each.value.type == "LINUX_LAMBDA_CONTAINER" ? null : 60

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = each.value.compute_type
    image           = each.value.image
    privileged_mode = each.value.privileged_mode
    type            = each.value.type
  }

  source {
    buildspec = "aws/org1/buildspec_plan.yaml"
    type      = "CODEPIPELINE"
  }

}
