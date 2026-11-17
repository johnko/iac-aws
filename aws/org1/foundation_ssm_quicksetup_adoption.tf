# SSM Quick Setup CloudFormation Adoption
# This file adopts the existing AWS Quick Setup CloudFormation stacks into Terraform
#
# To import existing stacks:
#   terraform import aws_cloudformation_stack.quicksetup_local_deployment_roles AWS-QuickSetup-SSM-LocalDeploymentRolesStack
#   terraform import aws_cloudformation_stack.quicksetup_lifecycle StackSet-AWS-QuickSetup-SSM-LA-13yyq-e031431c-a58d-438d-9c06-a1f353961c3f
#
# NOTE: These stacks are StackSet-managed. Consider managing them via StackSets rather than
# direct stack adoption if you need multi-account deployment.

# SSM Quick Setup CloudFormation Stacks - Terraform Management
# This file adopts and manages the existing AWS Quick Setup CloudFormation stacks
#
# These stacks were originally created by AWS SSM Quick Setup and contain:
# - SSM associations (EnableExplorer, EnableDHMC, EnableAREX, AgentUpdate, Inventory)
# - IAM roles for automation
# - S3 buckets for diagnosis
# - Cross-account execution roles
#
# To import existing stacks (one-time operation):
# terraform plan -generate-config-out=generated.tf
# Or manually:
#   terraform import aws_cloudformation_stack.quicksetup_local_deployment_roles AWS-QuickSetup-SSM-LocalDeploymentRolesStack
#   terraform import aws_cloudformation_stack.quicksetup_lifecycle StackSet-AWS-QuickSetup-SSM-LA-13yyq-e031431c-a58d-438d-9c06-a1f353961c3f

# Import existing Local Deployment Roles stack
import {
  to = aws_cloudformation_stack.quicksetup_local_deployment_roles
  id = "AWS-QuickSetup-SSM-LocalDeploymentRolesStack"
}

# Import existing Lifecycle Automation stack
import {
  to = aws_cloudformation_stack.quicksetup_lifecycle
  id = "StackSet-AWS-QuickSetup-SSM-LA-13yyq-e031431c-a58d-438d-9c06-a1f353961c3f"
}

locals {
  quicksetup_configuration_id = "13yyq"
  quicksetup_home_region      = "us-east-2"
  quicksetup_delegated_account_id = "" # Set to organization delegated account ID if using organizations
}

# Load the CloudFormation template bodies
data "local_file" "quicksetup_lifecycle_template" {
  filename = "${path.module}/ssm_quicksetup_templates/main_lifecycle.json"
}

data "local_file" "quicksetup_local_roles_template" {
  filename = "${path.module}/ssm_quicksetup_templates/local_deployment_roles.json"
}

# AWS CloudFormation Stack - Local Deployment Roles
# This stack creates the LocalAdministrationRole and LocalExecutionRole
# required by Quick Setup to perform operations in this account
resource "aws_cloudformation_stack" "quicksetup_local_deployment_roles" {
  name = "AWS-QuickSetup-SSM-LocalDeploymentRolesStack"

  template_body = data.local_file.quicksetup_local_roles_template.content

  parameters = {
    QSConfigurationType          = "LA" # Local Account
    OptInRegions                 = "ca-central-1,ca-west-1,us-east-1,us-west-2,us-east-2"
    LocalAdministrationRoleName  = "AWS-QuickSetup-LocalAdministrationRole"
    LocalExecutionRoleName       = "AWS-QuickSetup-LocalExecutionRole"
    UseAWSManagedPolicy          = "true"
  }

  capabilities = ["CAPABILITY_IAM"]

  tags = {
    Terraform   = "true"
    QuickSetup  = "SSM"
    Environment = "management"
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to template_body to avoid unnecessary updates
      # The template content is managed separately in version control
      template_body,
    ]
  }
}

# AWS CloudFormation Stack - Main Lifecycle Automation
# This stack creates all SSM associations and supporting resources
resource "aws_cloudformation_stack" "quicksetup_lifecycle" {
  name = "StackSet-AWS-QuickSetup-SSM-LA-${local.quicksetup_configuration_id}-e031431c-a58d-438d-9c06-a1f353961c3f"

  template_body = data.local_file.quicksetup_lifecycle_template.content

  parameters = {
    QSType                        = "LA" # Local Account
    QSConfigurationId             = local.quicksetup_configuration_id
    DelegatedAccountId            = local.quicksetup_delegated_account_id
    HomeRegion                    = local.quicksetup_home_region
    S3BucketEncryptionKeyArn      = ""
    CreateRemediationRoles        = "true"
    QSAttachConfigurationPolicy   = "false"
    QSPrincipalOrgId              = ""
    EnableDHMCSchedule            = "rate(1 day)"
    AgentUpdateSchedule           = "rate(14 days)"
    InventoryCollectionSchedule   = "rate(12 hours)"
  }

  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND"]

  tags = {
    Terraform   = "true"
    QuickSetup  = "SSM"
    ManagedBy   = "Terraform"
  }

  depends_on = [aws_cloudformation_stack.quicksetup_local_deployment_roles]

  lifecycle {
    ignore_changes = [
      template_body,
    ]
  }
}

# Outputs
output "quicksetup_local_admin_role_arn" {
  description = "ARN of the Quick Setup local administration role"
  value       = aws_cloudformation_stack.quicksetup_local_deployment_roles.outputs["LocalAdministrationRoleARN"]
}

output "quicksetup_local_execution_role_arn" {
  description = "ARN of the Quick Setup local execution role"
  value       = aws_cloudformation_stack.quicksetup_local_deployment_roles.outputs["LocalExecutionRoleARN"]
}