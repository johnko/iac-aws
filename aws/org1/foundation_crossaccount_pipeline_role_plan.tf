resource "aws_iam_role" "crossaccount_terraform_plan" {
  name = "CrossAccountPipelineRole-TerraformPlan"
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

resource "aws_iam_role_policy_attachments_exclusive" "crossaccount_terraform_plan" {
  role_name = aws_iam_role.crossaccount_terraform_plan.name
  policy_arns = [
    "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess" # ViewOnly to avoid reading sensitive data like Secrets or S3
  ]
}

locals {
  crossaccount_inline_policies_plan = {
    # This role starts with ViewOnly to avoid reading sensitive data like Secrets or S3
    # Here, be very selective what permissions are granted
    WriteTerraformStateReadSSMParam = {
      enabled_aws_account_ids = keys(local.all_aws_account_ids)
      policy_template = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            # Allow write to tfstate bucket
            "Action" : [
              "s3:DeleteObject",
              "s3:GetObject",
              "s3:GetObjectVersion",
              "s3:PutObject",
            ],
            "Resource" : [
              "arn:aws:s3:::tfstate-111122223333",
              "arn:aws:s3:::tfstate-111122223333/*"
            ],
            "Effect" : "Allow"
          },
          {
            # Read tag policy
            "Action" : [
              "tag:Describe*",
              "tag:Get*",
              "tag:ListRequiredTags",
            ],
            "Resource" : "*",
            "Effect" : "Allow"
          },
        ]
      })
    }
    ReadSensitive = {
      enabled_aws_account_ids = ["${var.aws_account_id_deployment_builds}"]
      policy_template = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            # Allow to get S3 Files from specific buckets
            "Action" : [
              "s3:Get*",
            ],
            "Resource" : [
              "arn:aws:s3:::codepipeline-111122223333",
            ],
            "Effect" : "Allow"
          },
          {
            # Allow to get SSM Parameter
            "Action" : [
              "ssm:GetParameter*",
            ],
            "Resource" : [
              "arn:aws:ssm:*:111122223333:parameter/TF_VAR_*"
            ],
            "Effect" : "Allow"
          },
        ]
      })
    }
    ReadSensitiveEncrypted = {
      enabled_aws_account_ids = ["${var.aws_account_id_management}"]
      policy_template = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            # Allow to decrypt using IAM Identity Center multi region kms key
            "Action" : [
              "kms:Decrypt",
            ],
            "Resource" : local.aws_kms_key_identitycenter_arns,
            "Effect" : "Allow"
          },
        ]
      })
    }
    TaggedReadPermissions1 = {
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
              "codebuild:BatchGet*",
              "codebuild:Describe*",
              "codebuild:Get*",
              "codeconnections:Get*",
              "codeconnections:List*",
              "codepipeline:Get*",
              "codepipeline:List*",
              "events:Describe*",
              "events:List*",
              "kms:Describe*",
              "kms:Get*",
              "lambda:Describe*",
              "lambda:Get*",
              "lambda:List*",
              "resource-explorer-2:Get*",
              "resource-explorer-2:List*",
              "s3:ListBucket",
              "sns:Get*",
              "sns:List*",
            ],
            "Resource" : "*",
            "Effect" : "Allow"
          },
        ]
      })
    }
    UntaggedReadPermissions1 = {
      enabled_aws_account_ids = keys(local.all_aws_account_ids)
      policy_template = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Action" : [
              "chatbot:Describe*",
              "controltower:Describe*",
              "controltower:Get*",
              "controltower:List*",
              "iam:Get*",
              "iam:List*",
              "iam:Simulate*",
              "identitystore:Describe*",
              "identitystore:Get*",
              "identitystore:List*",
              "kms:List*",
              "organizations:Describe*",
              "organizations:List*",
              "s3:Get*Configuration",
              "s3:GetBucket*",
              "ssm:Describe*",
              "ssm:List*",
              "sso:Describe*",
              "sso:Get*",
              "sso:List*",
            ],
            "Resource" : "*",
            "Effect" : "Allow"
          },
        ]
      })
    }
  }
}

resource "aws_iam_role_policy" "crossaccount_terraform_plan" {
  for_each = {
    for k, v in local.crossaccount_inline_policies_plan :
    k => v if contains(v.enabled_aws_account_ids, data.aws_caller_identity.current.account_id)
  }

  name   = each.key
  role   = aws_iam_role.crossaccount_terraform_plan.id
  policy = replace(each.value.policy_template, "111122223333", data.aws_caller_identity.current.account_id)
}

resource "aws_iam_role_policies_exclusive" "crossaccount_terraform_plan" {
  role_name    = aws_iam_role.crossaccount_terraform_plan.name
  policy_names = keys(aws_iam_role_policy.crossaccount_terraform_plan)
}
