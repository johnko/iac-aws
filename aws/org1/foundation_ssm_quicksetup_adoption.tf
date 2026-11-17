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

# Import existing Quick Setup StackSet
import {
  to = aws_cloudformation_stack_set.quicksetup_ssm
  id = "AWS-QuickSetup-SSM-LA-13yyq"
}

# Import existing StackSet Instance for us-east-2
import {
  to = aws_cloudformation_stack_set_instance.quicksetup_ssm_useast2
  id = "764858776402,us-east-2,AWS-QuickSetup-SSM-LA-13yyq"
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

# AWS CloudFormation StackSet - Quick Setup SSM
# This StackSet creates all Quick Setup resources including:
# - SSM associations (EnableExplorer, EnableDHMC, EnableAREX, AgentUpdate, Inventory)
# - Local deployment IAM roles
# - S3 buckets for diagnosis
# - Remediation roles
resource "aws_cloudformation_stack_set" "quicksetup_ssm" {
  name        = "AWS-QuickSetup-SSM-LA-13yyq"
  description = "CFN StackSet for QuickSetup b3625d04-20a3-441d-b3be-9c346952285a."

  template_body = data.local_file.quicksetup_lifecycle_template.content

  permission_model = "SELF_MANAGED"

  parameters = {
    QSType                      = "LA" # Local Account
    QSConfigurationId           = "13yyq"
    DelegatedAccountId          = ""
    HomeRegion                  = "us-east-2"
    S3BucketEncryptionKeyArn    = ""
    CreateRemediationRoles      = "true"
    QSAttachConfigurationPolicy = "false"
    QSPrincipalOrgId            = ""
    EnableDHMCSchedule          = "rate(1 day)"
    AgentUpdateSchedule         = "rate(14 days)"
    InventoryCollectionSchedule = "rate(12 hours)"
  }

  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND"]

  tags = {
    Terraform  = "true"
    QuickSetup = "SSM"
    ManagedBy  = "Terraform"
  }

  lifecycle {
    ignore_changes = [
      template_body,
    ]
  }
}

# StackSet Instance for us-east-2
resource "aws_cloudformation_stack_set_instance" "quicksetup_ssm_useast2" {
  stack_set_name = aws_cloudformation_stack_set.quicksetup_ssm.id
  account_id     = var.aws_account_id
  region         = "us-east-2"
}


# NOTE: The LocalDeploymentRolesStack is a separate stack (not part of the StackSet)
# It was created by Quick Setup to provide the administration/execution roles.
# We manage it as an individual stack since it's not part of the StackSet.
resource "aws_cloudformation_stack" "quicksetup_local_deployment_roles" {
  name = "AWS-QuickSetup-SSM-LocalDeploymentRolesStack"

  template_body = data.local_file.quicksetup_local_roles_template.content

  parameters = {
    QSConfigurationType         = "LA"
    OptInRegions                = "ca-central-1,ca-west-1,us-east-1,us-west-2,us-east-2"
    LocalAdministrationRoleName = "AWS-QuickSetup-LocalAdministrationRole"
    LocalExecutionRoleName      = "AWS-QuickSetup-LocalExecutionRole"
    UseAWSManagedPolicy         = "true"
  }

  capabilities = ["CAPABILITY_IAM"]

  tags = {
    Terraform   = "true"
    QuickSetup  = "SSM"
    Environment = "management"
  }

  lifecycle {
    ignore_changes = [
      template_body,
    ]
  }
}


# Outputs
output "quicksetup_stack_set_id" {
  description = "ID of the Quick Setup SSM StackSet"
  value       = aws_cloudformation_stack_set.quicksetup_ssm.id
}

output "quicksetup_local_admin_role_arn" {
  description = "ARN of the Quick Setup local administration role"
  value       = aws_cloudformation_stack.quicksetup_local_deployment_roles.outputs["LocalAdministrationRoleARN"]
}

output "quicksetup_local_execution_role_arn" {
  description = "ARN of the Quick Setup local execution role"
  value       = aws_cloudformation_stack.quicksetup_local_deployment_roles.outputs["LocalExecutionRoleARN"]
}