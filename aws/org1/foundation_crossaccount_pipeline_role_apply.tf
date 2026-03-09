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
                "codebuild:Delete*",
                "codebuild:PutResourcePolicy",
                "codebuild:Update*",
                "codepipeline:Delete*",
                "codepipeline:PutActionRevision",
                "codepipeline:UntagResource",
                "codepipeline:Update*",
                "events:Delete*",
                "events:Disable*",
                "events:Enable*",
                "events:Put*",
                "events:Remove*",
                "events:UntagResource",
                "events:Update*",
                # "kms:Describe*",
                # "kms:Get*",
                # "kms:List*",
                "lambda:Add*",
                "lambda:Delete*",
                "lambda:Publish*",
                "lambda:Put*",
                "lambda:Remove*",
                "lambda:Untag*",
                "lambda:Update*",
                # "resource-explorer-2:Get*",
                # "resource-explorer-2:List*",
                "s3:DeleteAcc*",
                "s3:DeleteBucket*",
                "s3:PutAcc*",
                "s3:Put*Configuration",
                "s3:UntagResource",
                "s3:Update*Configuration",
                "sns:*Permission",
                "sns:DeleteTopic",
                "sns:PutDataProtectionPolicy",
                "sns:Set*Attributes",
                "sns:Subscribe",
                "sns:Unsubscribe",
                "sns:UntagResource",
                "ssm:RemoveTagsFromResource",
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
                "chatbot:*SlackChannel*",
                "codebuild:Create*",
                "codepipeline:Create*",
                "codepipeline:TagResource",
                "codestar-connections:PassConnection", # For modifying CodePipeline
                "events:Create*",
                "events:TagResource",
                "iam:Attach*Policy", # iam permissions here because SSO/AWS Identity Center may not have tagged the resources
                "iam:Create*Role",
                "iam:CreatePolicy*",
                "iam:CreateRole",
                "iam:DeletePolicy*",
                "iam:DeleteRole*",
                "iam:Detach*Policy",
                "iam:PutRole*",
                "iam:Tag*",
                "iam:Untag*",
                "iam:UpdateAssumeRolePolicy",
                "iam:UpdateRole*",
                "lambda:Create*",
                "lambda:Tag*",
                # "organizations:List*",
                "s3:CreateAcc*",
                "s3:CreateBucket*",
                "s3:PutBucket*",
                "s3:TagResource",
                "sns:CreateTopic",
                "sns:TagResource",
                "ssm:AddTagsToResource",
                "sso:*PermissionSet", # sso permissions here because SSO/AWS Identity Center may not have tagged the resources
                "sso:PutPermissions*",
              ],
              "Resource" : "*",
              "Effect" : "Allow"
            },
          ]
        })
      }
      CodePipelinePassRole = {
        enabled_aws_account_ids = ["${var.aws_account_id_deployment_builds}"]
        policy_template = jsonencode({
          "Version" : "2012-10-17",
          "Statement" : [
            {
              "Action" : [
                "iam:PassRole",
              ],
              "Resource" : [
                "arn:aws:iam::${var.aws_account_id_deployment_builds}:role/CodePipelineRole-TerraformPipelines",
                "arn:aws:iam::${var.aws_account_id_deployment_builds}:role/service-role/AWSChatbotRole-test-awschatbot",
              ],
              "Effect" : "Allow"
            }
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
