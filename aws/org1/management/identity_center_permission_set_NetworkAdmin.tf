data "aws_ssoadmin_instances" "sso" {}

resource "aws_ssoadmin_permission_set" "NetworkAdministrator" {
  name         = "NetworkAdministrator"
  description  = "Custom role to manage networks, eg. delete default VPC"
  instance_arn = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
}
resource "aws_ssoadmin_managed_policy_attachments_exclusive" "NetworkAdministrator" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.NetworkAdministrator.arn

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess",
    # AWS Billing
    "arn:aws:iam::aws:policy/AWSBillingReadOnlyAccess",
    # delete default VPC
    "arn:aws:iam::aws:policy/AWSCloudShellFullAccess",
    "arn:aws:iam::aws:policy/job-function/NetworkAdministrator",
    # AWS Resource Explorer
    "arn:aws:iam::aws:policy/ResourceGroupsandTagEditorFullAccess",
    "arn:aws:iam::aws:policy/ResourceGroupsTaggingAPITagUntagSupportedResources",
    # AWS Control Tower
    "arn:aws:iam::aws:policy/AWSServiceCatalogEndUserFullAccess",
  ]
}
resource "aws_ssoadmin_permission_set_inline_policy" "AllowCreateAccount" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.NetworkAdministrator.arn
  inline_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowCreateAccount",
        "Effect" : "Allow",
        "Action" : [
          "controltower:CreateManagedAccount",
          "controltower:Describe*",
          "controltower:Get*",
          "controltower:List*",
          "controltower:PerformPreLaunchChecks",
          "controltower:TagResource",
          "controltower:UntagResource"
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}

data "aws_identitystore_group" "NetworkAdmins" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = "NetworkAdmins"
    }
  }
}

data "aws_organizations_account" "management" {
  account_id = var.aws_account_id_management
}

resource "aws_ssoadmin_account_assignment" "NetworkAdministrator" {
  for_each = merge(aws_organizations_account.security_account, { "management" : data.aws_organizations_account.management })

  instance_arn       = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.NetworkAdministrator.arn

  principal_id   = data.aws_identitystore_group.NetworkAdmins.group_id
  principal_type = "GROUP"

  target_id   = each.value.id
  target_type = "AWS_ACCOUNT"
}
