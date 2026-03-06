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
                # "events:Describe*",
                # "events:List*",
                "iam:Attach*Policy",
                "iam:DeletePolicy*",
                "iam:DeleteRole*",
                "iam:Detach*Policy",
                "iam:PutRole*",
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
                "s3:DeleteAcc*",
                "s3:DeleteBucket*",
                "s3:PutAcc*",
                "s3:Put*Configuration",
                "s3:PutBucket*",
                "s3:UntagResource",
                "s3:Update*Configuration",
                "sns:*Permission",
                "sns:DeleteTopic",
                "sns:PutDataProtectionPolicy",
                "sns:Set*Attributes",
                "sns:Subscribe",
                "sns:Unsubscribe",
                "sns:UntagResource",
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
                "codebuild:Create*",
                "codepipeline:Create*",
                "codepipeline:TagResource",
                "codestar-connections:PassConnection", # For modifying CodePipeline
                "iam:Create*Role",
                "iam:CreatePolicy*",
                "iam:CreateRole",
                "iam:Tag*",
                # "organizations:List*",
                "s3:CreateAcc*",
                "s3:CreateBucket*",
                "s3:TagResource",
                "sns:CreateTopic",
                "sns:TagResource",
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
                "arn:aws:iam::${var.aws_account_id_deployment_builds}:role/CodePipelineRole-TerraformPipelines"
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
