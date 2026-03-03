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
      # Here, be very selective what permissions are granted
      TaggedWritePermissions1 = {
        enabled_aws_account_ids = keys(local.all_aws_account_ids)
        policy_template = jsonencode({
          "Version" : "2012-10-17",
          "Statement" : [
            {
              "Condition" : {
                # https://docs.aws.amazon.com/IAM/latest/UserGuide/access_tags.html#access_tags_control-resources
                "StringEquals" : { "aws:ResourceTag/iacdeployer" : "terraform" }
              },
              "Action" : [
                # "codebuild:BatchGet*",
                # "codebuild:Describe*",
                # "codebuild:Get*",
                # "codeconnections:Get*",
                # "codeconnections:List*",
                # "codepipeline:Get*",
                # "codepipeline:List*",
                # "events:Describe*",
                # "events:List*",
                "iam:Attach*",
                "iam:CreatePolicy*",
                "iam:CreateRole",
                "iam:CreateServiceLinkedRole",
                "iam:DeletePolicy*",
                "iam:DeleteRole*",
                "iam:Detach*",
                "iam:Put*",
                "iam:Tag*",
                "iam:Untag*",
                "iam:UpdateAssumeRolePolicy",
                "iam:UpdateRole*",
                # "kms:Describe*",
                # "kms:Get*",
                # "kms:List*",
                # "lambda:Describe*",
                # "lambda:Get*",
                # "resource-explorer-2:Get*",
                # "resource-explorer-2:List*",
                # "s3:ListBucket",
                # "sns:Get*",
                # "sns:List*",
                # "ssm:List*",
                # "sso:Get*",
              ],
              "Resource" : "*",
              "Effect" : "Allow"
            },
          ]
        })
      }
      UntaggedWritePermissions1 = {
        enabled_aws_account_ids = keys(local.all_aws_account_ids)
        policy_template = jsonencode({
          "Version" : "2012-10-17",
          "Statement" : [
            {
              "Action" : [
                # "chatbot:Describe*",
                # "organizations:List*",
                # "s3:GetAccelerateConfiguration",
                "s3:CreateBucket",
                # "s3:GetEncryptionConfiguration",
                # "s3:GetLifecycleConfiguration",
                # "s3:GetReplicationConfiguration",
                # "ssm:Describe*",
                # "sso:Describe*",
                # "sso:List*",
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
  policy = replace(each.value.policy_template, "111122223333", data.aws_caller_identity.current.account_id)
}

resource "aws_iam_role_policies_exclusive" "crossaccount_terraform_apply" {
  role_name    = aws_iam_role.crossaccount_terraform_apply.name
  policy_names = keys(aws_iam_role_policy.crossaccount_terraform_apply)
}
