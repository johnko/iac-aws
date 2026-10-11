resource "aws_iam_role" "crossaccount_terraform_apply" {
  name = "CrossAccountPipelineRole-TerraformApply"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${var.aws_account_id_deployment_builds}:root"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "crossaccount_terraform_apply" {
  role_name = aws_iam_role.crossaccount_terraform_apply.name
  policy_arns = [
    "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess" # ViewOnly to avoid reading sensitive data like Secrets or S3
  ]
}

locals {
  crossaccount_inline_policies_apply = merge(
    local.crossaccount_inline_policies_plan,
    {
      # This role starts with ViewOnly to avoid reading sensitive data like Secrets or S3
      # Be very selective what permissions are granted
      # TaggedWritePermissions1 = {
      #   enabled_aws_account_ids = keys(local.all_aws_account_ids)
      #   policy = jsonencode({
      #     "Version" : "2012-10-17",
      #     "Statement" : [
      #       {
      #         "Condition" : {
      #           # https://docs.aws.amazon.com/IAM/latest/UserGuide/access_tags.html#access_tags_control-resources
      #           "StringEquals" : { "aws:ResourceTag/iacdeployer" : "terraform" }
      #         },
      #         "Action" : [
      #           "iam:PassRole"
      #         ],
      #         "Resource" : "*",
      #         "Effect" : "Allow"
      #       },
      #     ]
      #   })
      # }
      UntaggedPermissions1 = {
        enabled_aws_account_ids = keys(local.all_aws_account_ids)
        policy = jsonencode({
          "Version" : "2012-10-17",
          "Statement" : [
            {
              "Action" : [
                "chatbot:*",
                "codebuild:*",
                "codepipeline:*",
                "codestar-connections:*",
                "events:*",
                "iam:*",
                "kms:*",
                "lambda:*",
                "s3:*",
                "sns:*",
                "ssm:*",
                "sso:*",
              ],
              "Resource" : "*",
              "Effect" : "Allow"
            },
          ]
        })
      }
      IAMPassRolePermissions1 = {
        enabled_aws_account_ids = keys(local.all_aws_account_ids)
        policy = jsonencode({
          "Version" : "2012-10-17",
          "Statement" : [
            {
              "Condition" : {
                # https://docs.aws.amazon.com/IAM/latest/UserGuide/access_tags.html#access_tags_control-resources
                "StringEquals" : { "aws:ResourceTag/iacdeployer" : "terraform" }
              },
              "Action" : [
                "iam:PassRole"
              ],
              "Resource" : "*",
              "Effect" : "Allow"
            },
          ]
        })
      }
    }
  )
}

resource "aws_iam_role_policy" "crossaccount_terraform_apply" {
  for_each = {
    for k, v in local.crossaccount_inline_policies_apply :
    k => v if contains(v.enabled_aws_account_ids, data.aws_caller_identity.current.account_id)
  }

  name   = each.key
  role   = aws_iam_role.crossaccount_terraform_apply.id
  policy = each.value.policy
}

resource "aws_iam_role_policies_exclusive" "crossaccount_terraform_apply" {
  role_name    = aws_iam_role.crossaccount_terraform_apply.name
  policy_names = keys(aws_iam_role_policy.crossaccount_terraform_apply)
}
