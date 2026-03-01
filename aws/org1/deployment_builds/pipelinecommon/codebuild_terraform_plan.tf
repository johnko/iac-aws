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
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "StringEquals" : {
            "aws:SourceAccount" : "${data.aws_caller_identity.current.account_id}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "terraform_plan" {
  role_name = aws_iam_role.terraform_plan.name
  policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]
}

resource "aws_iam_role_policy" "CodeBuildRolePlan-CommonPolicy" {
  name   = "CodeBuildRoleTerraformCommonPolicy"
  role   = aws_iam_role.terraform_plan.id
  policy = local.terraform_common_policy
}

resource "aws_iam_role_policy" "CodeBuildRolePlanPolicy" {
  name = "CodeBuildRolePlanPolicy"
  role = aws_iam_role.terraform_plan.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/TerraformPlan-*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/TerraformPlan-*:log-stream:*"
        ],
        "Effect" : "Allow"
      },
      {
        # See https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-CodeBuild.html#edit-role-codebuild
        "Action" : [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:BatchGetBuildBatches",
          "codebuild:StartBuildBatch"
        ],
        "Resource" : [
          for k, v in aws_codebuild_project.terraform_plan : v.arn
        ],
        "Effect" : "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policies_exclusive" "terraform_plan" {
  role_name = aws_iam_role.terraform_plan.name
  policy_names = [
    resource.aws_iam_role_policy.CodeBuildRolePlan-CommonPolicy.name,
    resource.aws_iam_role_policy.CodeBuildRolePlanPolicy.name,
  ]
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
