# SSM Quick Setup Configuration Manager - Default Host Management (DHMC)
# This configuration manager is deployed in the management account to manage
# Default Host Management across all organization accounts.

locals {
  quicksetup_local_admin_role_arn = "arn:aws:iam::${var.aws_account_id}:role/${local.quicksetup_local_admin_role_name}"

  quicksetup_target_regions = "us-east-2,us-east-1,us-west-2,ca-central-1,ca-west-1"

  # All organization account IDs except management for TargetAccounts
  # Management account is excluded because it can't enable LOCAL
  quicksetup_target_accounts = join(",", [
    for account_id in keys(local.all_aws_account_ids) : account_id if account_id != var.aws_account_id_management
  ])
}

# Configuration Manager for Default Host Management (DHMC)
resource "aws_ssmquicksetup_configuration_manager" "dhmc" {
  name        = "SSM-Quick-Setup-DHMC-Terraform"
  description = "Default Host Management Configuration managed by Terraform"

  configuration_definition {
    local_deployment_administration_role_arn = local.quicksetup_local_admin_role_arn
    local_deployment_execution_role_name     = local.quicksetup_local_exec_role_name
    type                                     = "AWSQuickSetupType-DHMC"

    parameters = {
      "UpdateSsmAgent" = "true"
      "TargetAccounts" = local.quicksetup_target_accounts
      "TargetRegions"  = local.quicksetup_target_regions
    }
  }

  tags = {
    Terraform  = "true"
    ManagedBy  = "Terraform"
    QuickSetup = "DHMC"
  }

  depends_on = [
    aws_cloudformation_stack.quicksetup_local_deployment_roles
  ]
}
