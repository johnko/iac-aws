resource "aws_iam_role" "terraform_apply" {
  for_each = local.all_aws_account_ids

  name = "CodeBuildRole-TerraformApply-${each.key}"
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
  for_each = local.all_aws_account_ids

  role_name   = aws_iam_role.terraform_apply[each.key].name
  policy_arns = []
}

resource "aws_iam_role_policy" "CodeBuildRoleApply-CommonPolicy" {
  for_each = local.all_aws_account_ids

  name   = "CodeBuildRoleTerraformCommonPolicy"
  role   = aws_iam_role.terraform_apply[each.key].id
  policy = local.terraform_common_policy
}

resource "aws_iam_role_policy" "CodeBuildRoleApplyPolicy" {
  for_each = local.all_aws_account_ids

  name = "CodeBuildRoleApplyPolicy"
  role = aws_iam_role.terraform_apply[each.key].id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceAccount" : "${data.aws_caller_identity.current.account_id}"
          }
        },
        "Action" : [
          "logs:CreateLogGroup",  # default
          "logs:CreateLogStream", # default
          "logs:PutLogEvents",    # default
        ],
        "Resource" : [
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/TerraformApply-${each.key}-*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/TerraformApply-${each.key}-*:*"
        ],
        "Effect" : "Allow"
      },
      {
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceAccount" : "${data.aws_caller_identity.current.account_id}"
          }
        },
        "Effect" : "Allow",
        "Action" : [
          "codebuild:BatchPutCodeCoverages", # default
          "codebuild:BatchPutTestCases",     # default
          "codebuild:CreateReport",          # default
          "codebuild:CreateReportGroup",     # default
          "codebuild:UpdateReport",          # default
        ],
        "Resource" : [
          "arn:aws:codebuild:*:${data.aws_caller_identity.current.account_id}:report-group/TerraformApply-${each.key}-*"
        ]
      },
      {
        # Allow Assume Cross Account Pipeline Role
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceAccount" : "${each.key}"
          }
        },
        "Action" : [
          "sts:AssumeRole"
        ],
        "Resource" : [
          "arn:aws:iam::${each.key}:role/CrossAccountPipelineRole-TerraformApply"
        ],
        "Effect" : "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policies_exclusive" "terraform_apply" {
  for_each = local.all_aws_account_ids

  role_name = aws_iam_role.terraform_apply[each.key].name
  policy_names = [
    aws_iam_role_policy.CodeBuildRoleApply-CommonPolicy[each.key].name,
    aws_iam_role_policy.CodeBuildRoleApplyPolicy[each.key].name,
  ]
}

resource "aws_codebuild_project" "terraform_apply" {
  for_each = merge(values({
    for a, z in local.all_aws_account_ids : a => {
      for k, v in local.codebuild_types : "${a}/${k}" => merge(v, {
        "aws_account_id" : a,
        "codebuild_type" : k,
      })
    }
  })...)

  region = each.value.region

  # Per account CodeBuild Project + CodeBuild IAM Role to prevent 1 account buildspec from being able to go into another AWS account
  name         = "TerraformApply-${each.value.aws_account_id}-${each.value.codebuild_type}"
  service_role = aws_iam_role.terraform_apply[each.value.aws_account_id].arn

  build_timeout  = each.value.build_timeout
  queued_timeout = each.value.queued_timeout

  artifacts {
    type = "CODEPIPELINE"
  }

  dynamic "cache" {
    for_each = each.value.type != "LINUX_LAMBDA_CONTAINER" ? [1] : []

    content {
      modes = [
        "LOCAL_CUSTOM_CACHE"
      ]
      type = "LOCAL"
    }
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
