# SSM Quick Setup Configuration Manager (Native Terraform)
# Replaces CloudFormation StackSet management with native aws_ssmquicksetup_configuration_manager
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssmquicksetup_configuration_manager

locals {
  quicksetup_local_admin_role_name = "AWS-QuickSetup-SSM-LocalAdministrationRole"
  quicksetup_local_admin_role_arn  = "arn:aws:iam::${var.aws_account_id}:role/${local.quicksetup_local_admin_role_name}"
  quicksetup_local_exec_role_name  = "AWS-QuickSetup-SSM-LocalExecutionRole"
  quicksetup_target_regions        = "us-east-2,us-east-1,us-west-2,ca-central-1,ca-west-1"
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

# Configuration Manager for SSM Host Management (Agent Update)
resource "aws_ssmquicksetup_configuration_manager" "ssm_host_mgmt" {
  name        = "SSM-Quick-Setup-HostMgmt-Terraform"
  description = "SSM Host Management (Agent Update) managed by Terraform"

  configuration_definition {
    local_deployment_administration_role_arn = local.quicksetup_local_admin_role_arn
    local_deployment_execution_role_name     = local.quicksetup_local_exec_role_name
    type                                     = "AWSQuickSetupType-SSMHostMgmt"

    parameters = {
      "UpdateSsmAgent"         = "true"
      "UpdateEc2LaunchAgent"   = "true"
      "CollectInventory"       = "true"
      "ScanInstances"          = "true"
      "InstallCloudWatchAgent" = "true"
      "UpdateCloudWatchAgent"  = "true"
      "TargetType"             = "*"
      "TargetRegions"          = local.quicksetup_target_regions
    }
  }

  tags = {
    Terraform  = "true"
    ManagedBy  = "Terraform"
    QuickSetup = "SSMHostMgmt"
  }

  depends_on = [
    aws_cloudformation_stack.quicksetup_local_deployment_roles
  ]
}

# Configuration Manager for Resource Explorer
resource "aws_ssmquicksetup_configuration_manager" "resource_explorer" {
  name        = "SSM-Quick-Setup-ResourceExplorer-Terraform"
  description = "AWS Resource Explorer managed by Terraform"

  configuration_definition {
    local_deployment_administration_role_arn = local.quicksetup_local_admin_role_arn
    local_deployment_execution_role_name     = local.quicksetup_local_exec_role_name
    type                                     = "AWSQuickSetupType-ResourceExplorer"

    parameters = {
      "SelectedAggregatorRegion"  = "ca-central-1"
      "ReplaceExistingAggregator" = "true"
      "TargetRegions"             = local.quicksetup_target_regions
    }
  }

  tags = {
    Terraform  = "true"
    ManagedBy  = "Terraform"
    QuickSetup = "ResourceExplorer"
  }

  depends_on = [
    aws_cloudformation_stack.quicksetup_local_deployment_roles
  ]
}
