# SSM Quick Setup - Manage Resources Automation Configuration
# Creates an SSM Association for AWSQuickSetupType-SSM-ManageResources
# This association targets resources tagged with the QuickSetup automation tag
# Uses the region argument (supported in AWS provider 6.71.0+)

locals {
  # List of governed regions where this association should be applied
  ssm_manage_resources_regions = ["ca-central-1", "ca-west-1", "us-east-1", "us-east-2", "us-west-2"]
}

# ca-central-1 (default region - no region argument needed)
resource "aws_ssm_association" "ca_central_1_manage_resources" {
  name             = "AWSQuickSetupType-SSM-ManageResources"
  association_name = "Terraform-SystemAssociationForManageResources"

  targets {
    key    = "aws:NoOpAutomationTag"
    values = ["AWS-NoOpAutomationTarget-Value"]
  }
}

# ca-west-1
resource "aws_ssm_association" "ca_west_1_manage_resources" {
  region = "ca-west-1"

  name             = "AWSQuickSetupType-SSM-ManageResources"
  association_name = "Terraform-SystemAssociationForManageResources"

  targets {
    key    = "aws:NoOpAutomationTag"
    values = ["AWS-NoOpAutomationTarget-Value"]
  }
}

# us-east-1
resource "aws_ssm_association" "us_east_1_manage_resources" {
  region = "us-east-1"

  name             = "AWSQuickSetupType-SSM-ManageResources"
  association_name = "Terraform-SystemAssociationForManageResources"

  targets {
    key    = "aws:NoOpAutomationTag"
    values = ["AWS-NoOpAutomationTarget-Value"]
  }
}

# us-east-2
resource "aws_ssm_association" "us_east_2_manage_resources" {
  region = "us-east-2"

  name             = "AWSQuickSetupType-SSM-ManageResources"
  association_name = "Terraform-SystemAssociationForManageResources"

  targets {
    key    = "aws:NoOpAutomationTag"
    values = ["AWS-NoOpAutomationTarget-Value"]
  }
}

# us-west-2
resource "aws_ssm_association" "us_west_2_manage_resources" {
  region = "us-west-2"

  name             = "AWSQuickSetupType-SSM-ManageResources"
  association_name = "Terraform-SystemAssociationForManageResources"

  targets {
    key    = "aws:NoOpAutomationTag"
    values = ["AWS-NoOpAutomationTarget-Value"]
  }
}
