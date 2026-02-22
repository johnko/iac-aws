resource "aws_ssoadmin_permission_set" "BedrockUser" {
  name         = "BedrockUser"
  description  = "Custom role to manage Bedrock"
  instance_arn = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
}
resource "aws_ssoadmin_managed_policy_attachments_exclusive" "BedrockUser" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.BedrockUser.arn

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSCloudShellFullAccess",
    "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess",
    # AWS Billing
    "arn:aws:iam::aws:policy/AWSBillingReadOnlyAccess",
    # AWS Bedrock
    "arn:aws:iam::aws:policy/AmazonBedrockLimitedAccess",
  ]
}

resource "aws_ssoadmin_permission_set_inline_policy" "AllowCostExplorer" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.BedrockUser.arn
  inline_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowCostExplorer",
        "Effect" : "Allow",
        "Action" : [
          "ce:DescribeReport",
        ],
        "Resource" : [
          "*"
        ]
      },
    ]
  })
}

data "aws_identitystore_group" "BedrockUsers" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = "BedrockUsers"
    }
  }
}

resource "aws_ssoadmin_account_assignment" "BedrockUser" {
  for_each = merge({ "sandboxbedrock" : data.aws_organizations_account.sandboxbedrock })

  instance_arn       = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.BedrockUser.arn

  principal_id   = data.aws_identitystore_group.BedrockUsers.group_id
  principal_type = "GROUP"

  target_id   = each.value.id
  target_type = "AWS_ACCOUNT"
}
