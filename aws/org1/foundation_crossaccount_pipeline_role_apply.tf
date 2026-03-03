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
  crossaccount_inline_policies_apply = {
    # This role starts with ViewOnly to avoid reading sensitive data like Secrets or S3
    # Here, be very selective what permissions are granted
    ReadSSMParamWriteTerraformState = {
      enabled_aws_account_ids = keys(local.all_aws_account_ids)
      policy_template = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            # Allow write to tfstate bucket
            "Condition" : {
              "StringEquals" : {
                "aws:ResourceAccount" : "111122223333"
              }
            },
            "Action" : [
              "s3:DeleteObject",
              "s3:GetBucketAcl",
              "s3:GetBucketLocation",
              "s3:GetBucketPolicy",
              "s3:GetBucketVersioning",
              "s3:GetObject",
              "s3:GetObjectVersion",
              "s3:ListBucket",
              "s3:PutObject",
            ],
            "Resource" : [
              "arn:aws:s3:::tfstate-111122223333",
              "arn:aws:s3:::tfstate-111122223333/*"
            ],
            "Effect" : "Allow"
          },
          {
            # Allow to get SSM Parameter
            "Condition" : {
              "StringEquals" : {
                "aws:ResourceAccount" : "111122223333"
              }
            },
            "Action" : [
              "ssm:GetParameters",
            ],
            "Resource" : [
              "arn:aws:ssm:*:111122223333:parameter/TF_VAR_*"
            ],
            "Effect" : "Allow"
          },
          {
            # Read tag policy
            "Action" : [
              "tag:ListRequiredTags",
            ],
            "Resource" : "*",
            "Effect" : "Allow"
          },
        ]
      })
    }
    ReadPermissions1 = {
      enabled_aws_account_ids = keys(local.all_aws_account_ids)
      policy_template = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Action" : [
              "iam:GetAccessKeyLastUsed",
              "iam:GetAccountAuthorizationDetails",
              "iam:GetAccountName",
              "iam:GetAccountPasswordPolicy",
              "iam:GetAccountSummary",
              "iam:GetCloudFrontPublicKey",
              "iam:GetContextKeysForCustomPolicy",
              "iam:GetContextKeysForPrincipalPolicy",
              "iam:GetCredentialReport",
              "iam:GetDelegationRequest",
              "iam:GetGroup",
              "iam:GetGroupPolicy",
              "iam:GetHumanReadableSummary",
              "iam:GetInstanceProfile",
              "iam:GetLoginProfile",
              "iam:GetMFADevice",
              "iam:GetOpenIDConnectProvider",
              "iam:GetOrganizationsAccessReport",
              "iam:GetOutboundWebIdentityFederationInfo",
              "iam:GetPolicy",
              "iam:GetPolicyVersion",
              "iam:GetRole",
              "iam:GetRolePolicy",
              "iam:GetSAMLProvider",
              "iam:GetSSHPublicKey",
              "iam:GetServiceLastAccessedDetails",
              "iam:GetServiceLastAccessedDetailsWithEntities",
              "iam:GetServiceLinkedRoleDeletionStatus",
              "iam:GetUser",
              "iam:GetUserPolicy",
            ],
            "Resource" : "*",
            "Effect" : "Allow"
          },
        ]
      })
    }
  }
}

resource "aws_iam_role_policy" "crossaccount_terraform_apply" {
  for_each = local.crossaccount_inline_policies_apply

  name   = each.key
  role   = aws_iam_role.crossaccount_terraform_apply.id
  policy = each.value.policy
}

resource "aws_iam_role_policies_exclusive" "crossaccount_terraform_apply" {
  role_name    = aws_iam_role.crossaccount_terraform_apply.name
  policy_names = keys(aws_iam_role_policy.crossaccount_terraform_apply)
}
