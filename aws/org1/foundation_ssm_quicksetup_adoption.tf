# SSM Quick Setup CloudFormation Adoption
# This file adopts the existing AWS Quick Setup CloudFormation stacks into Terraform

# SSM Quick Setup CloudFormation Stacks - Terraform Management
# This file adopts and manages the existing AWS Quick Setup CloudFormation stacks
#
# These stacks were originally created by AWS SSM Quick Setup and contain:
# - IAM roles for automation
# - Cross-account execution roles

# Import block for existing CloudFormation stack
import {
  to = aws_cloudformation_stack.quicksetup_local_deployment_roles
  id = "AWS-QuickSetup-SSM-LocalDeploymentRolesStack"
}

# Load the CloudFormation template bodies
data "local_file" "quicksetup_local_roles_template" {
  filename = "${path.module}/ssm_quicksetup_templates/local_deployment_roles.json"
}

# NOTE: The LocalDeploymentRolesStack is a separate stack (not part of the StackSet)
# It was created by Quick Setup to provide the administration/execution roles.
# We manage it as an individual stack since it's not part of the StackSet.
resource "aws_cloudformation_stack" "quicksetup_local_deployment_roles" {
  region = "us-east-2"

  name = "AWS-QuickSetup-SSM-LocalDeploymentRolesStack"

  template_body = data.local_file.quicksetup_local_roles_template.content

  parameters = {
    QSConfigurationType         = "SSM"
    OptInRegions                = ""
    LocalAdministrationRoleName = "AWS-QuickSetup-SSM-LocalAdministrationRole"
    LocalExecutionRoleName      = "AWS-QuickSetup-SSM-LocalExecutionRole"
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
output "quicksetup_local_admin_role_arn" {
  description = "ARN of the Quick Setup local administration role"
  value       = aws_cloudformation_stack.quicksetup_local_deployment_roles.outputs["LocalAdministrationRoleARN"]
}

output "quicksetup_local_execution_role_arn" {
  description = "ARN of the Quick Setup local execution role"
  value       = aws_cloudformation_stack.quicksetup_local_deployment_roles.outputs["LocalExecutionRoleARN"]
}
