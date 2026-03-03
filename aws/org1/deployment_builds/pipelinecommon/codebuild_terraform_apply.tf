resource "aws_iam_role" "terraform_apply" {
  name = "CodeBuildRole-TerraformApply"
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

resource "aws_iam_role_policy_attachments_exclusive" "terraform_apply" {
  role_name = aws_iam_role.terraform_apply.name
  policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]
}

resource "aws_iam_role_policy" "CodeBuildRoleApply-CommonPolicy" {
  name   = "CodeBuildRoleTerraformCommonPolicy"
  role   = aws_iam_role.terraform_apply.id
  policy = local.terraform_common_policy
}

resource "aws_iam_role_policy" "CodeBuildRoleApplyPolicy" {
  name = "CodeBuildRoleApplyPolicy"
  role = aws_iam_role.terraform_apply.id

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
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/TerraformApply-*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/TerraformApply-*:log-stream:*"
        ],
        "Effect" : "Allow"
      },
      # {
      #   # See https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-CodeBuild.html#edit-role-codebuild
      #   "Action" : [
      #     "codebuild:BatchGetBuilds",
      #     "codebuild:StartBuild",
      #     "codebuild:BatchGetBuildBatches",
      #     "codebuild:StartBuildBatch"
      #   ],
      #   "Resource" : [
      #     for k, v in aws_codebuild_project.terraform_apply : v.arn
      #   ],
      #   "Effect" : "Allow"
      # },
    ]
  })
}

resource "aws_iam_role_policies_exclusive" "terraform_apply" {
  role_name = aws_iam_role.terraform_apply.name
  policy_names = [
    aws_iam_role_policy.CodeBuildRoleApply-CommonPolicy.name,
    aws_iam_role_policy.CodeBuildRoleApplyPolicy.name,
  ]
}

resource "aws_codebuild_project" "terraform_apply" {
  for_each = local.codebuild_types

  region = each.value.region

  name         = "TerraformApply-${each.key}"
  service_role = aws_iam_role.terraform_apply.arn

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
    buildspec = "aws/org1/buildspec_apply.yaml"
    type      = "CODEPIPELINE"
  }

}
