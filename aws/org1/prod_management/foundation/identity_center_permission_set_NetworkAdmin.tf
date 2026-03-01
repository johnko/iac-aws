resource "aws_ssoadmin_permission_set" "NetworkAdministrator" {
  name         = "NetworkAdministrator"
  description  = "Custom role to manage networks, eg. delete default VPC"
  instance_arn = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
}
resource "aws_ssoadmin_managed_policy_attachments_exclusive" "NetworkAdministrator" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.NetworkAdministrator.arn

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSCloudShellFullAccess",
    "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess",
    # AWS Billing
    "arn:aws:iam::aws:policy/AWSBillingReadOnlyAccess",
    # delete default VPC
    "arn:aws:iam::aws:policy/job-function/NetworkAdministrator",
    # AWS Resource Explorer
    "arn:aws:iam::aws:policy/ResourceGroupsandTagEditorFullAccess",
    "arn:aws:iam::aws:policy/ResourceGroupsTaggingAPITagUntagSupportedResources",
  ]
}

resource "aws_identitystore_group" "NetworkAdmins" {
  display_name      = "NetworkAdmins"
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso.identity_store_ids)[0]
}


resource "aws_ssoadmin_account_assignment" "NetworkAdministrator" {
  for_each = merge(
    aws_organizations_account.security_account,
    aws_organizations_account.deployment_account,
    aws_organizations_account.sandbox_account,
    { "management" : data.aws_organizations_account.management }
  )

  instance_arn       = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.NetworkAdministrator.arn

  principal_id   = aws_identitystore_group.NetworkAdmins.group_id
  principal_type = "GROUP"

  target_id   = each.value.id
  target_type = "AWS_ACCOUNT"
}
