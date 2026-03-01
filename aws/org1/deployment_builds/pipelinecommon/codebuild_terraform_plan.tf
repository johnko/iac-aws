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

  build_timeout  = each.value.build_timeout
  queued_timeout = each.value.queued_timeout

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
