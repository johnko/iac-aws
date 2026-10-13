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
    "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess", # ViewOnly avoids reading sensitive data like Secrets or S3
    "arn:aws:iam::aws:policy/ReadOnlyAccess",              # ReadOnly allows reading everything including sensitive data
  ]
}

locals {
  crossaccount_inline_policies_plan = {
    # This role starts with ViewOnly to avoid reading sensitive data like Secrets or S3
    # Here, be very selective what permissions are granted
    WriteTerraformStateReadSSMParam = {
      enabled_aws_account_ids = keys(local.all_aws_account_ids)
      policy = jsonencode({
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
            "Resource" : flatten(concat(
              [
                module.terraform_state.bucket.arn,
                "${module.terraform_state.bucket.arn}/*",
              ],
              flatten([
                for k, v in module.terraform_state_replica : [
                  "${v.bucket.arn}/*"
                ]
              ]),
            ))
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
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            # Allow to get S3 Files from specific buckets
            "Action" : [
              "s3:Get*",
            ],
            "Resource" : flatten([
              for k, v in local.codebuild_terraform_suffix_by_region : [
                "arn:aws:s3:::${format("codepipeline-%s-%s-an", data.aws_caller_identity.current.account_id, k)}",
                "arn:aws:s3:::${format("codepipeline-%s-%s-an", data.aws_caller_identity.current.account_id, k)}/*",
              ]
            ]),
            "Effect" : "Allow"
          },
          {
            # Allow to get SSM Parameter
            "Action" : [
              "ssm:GetParameter*",
            ],
            "Resource" : [
              "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/TF_VAR_*",
              "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/cached_*"
            ],
            "Effect" : "Allow"
          },
        ]
      })
    }
    ReadSensitiveEncrypted = {
      enabled_aws_account_ids = ["${var.aws_account_id_management}"]
      policy = jsonencode({
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
    UntaggedReadPermissions1 = {
      enabled_aws_account_ids = keys(local.all_aws_account_ids)
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Action" : [
              "controltower:Describe*", # these were not part of ReadOnlyAccess
              "controltower:Get*",      # these were not part of ReadOnlyAccess
              "controltower:List*",     # these were not part of ReadOnlyAccess
            ],
            "Resource" : "*",
            "Effect" : "Allow"
          },
        ]
      })
    }
    CDKBootstrapPermissions = {
      enabled_aws_account_ids = keys(local.all_aws_account_ids)
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Action" : [
              "cloudformation:CreateChangeSet",
              "cloudformation:CreateStack",
              "cloudformation:DeleteChangeSet",
              "cloudformation:DeleteStack",
              "cloudformation:DescribeChangeSet",
              "cloudformation:DescribeStacks",
              "cloudformation:ExecuteChangeSet",
              "cloudformation:GetTemplate",
              "cloudformation:UpdateStack",
            ],
            "Resource" : "arn:aws:cloudformation:*:${data.aws_caller_identity.current.account_id}:stack/CDKToolkit/*"
            "Effect" : "Allow"
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "ecr:CreateRepository",
              "ecr:PutLifecyclePolicy",
            ],
            "Resource" : "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/cdk-*"
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "iam:CreateRole",
              "iam:AttachRolePolicy",
              "iam:PutRolePolicy",
            ],
            "Resource" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/cdk-*"
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "s3:CreateBucket",
              "s3:PutBucketPublicAccessBlock",
            ],
            "Resource" : "arn:aws:s3:::cdktoolkit-stagingbucket-*"
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "ssm:DeleteParameter",
              "ssm:PutParameter",
            ],
            "Resource" : "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/cdk-bootstrap/*"
          },
        ]
      })
    }
    CDKDiffPermissions = {
      enabled_aws_account_ids = keys(local.all_aws_account_ids)
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Action" : [
              "cloudformation:CreateChangeSet",
            ],
            "Resource" : "*"
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
  policy = each.value.policy
}

resource "aws_iam_role_policies_exclusive" "crossaccount_terraform_plan" {
  role_name    = aws_iam_role.crossaccount_terraform_plan.name
  policy_names = keys(aws_iam_role_policy.crossaccount_terraform_plan)
}
