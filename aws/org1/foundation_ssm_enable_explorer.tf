# SSM Quick Setup - Enable Explorer Configuration
# Creates an SSM Association for AWS-EnableExplorer
# This association runs daily to enable Systems Manager Explorer
# Uses the region argument (supported in AWS provider 6.71.0+)

locals {
  # List of governed regions where this association should be applied
  ssm_enable_explorer_regions = ["ca-central-1", "ca-west-1", "us-east-1", "us-east-2", "us-west-2"]
}

# ca-central-1 (default region - no region argument needed)
resource "aws_ssm_association" "ca_central_1_enable_explorer" {
  name             = "AWS-EnableExplorer"
  association_name = "Terraform-SystemAssociationForEnableExplorer"

  schedule_expression = "rate(1 day)"

  targets {
    key    = "aws:NoOpAutomationTag"
    values = ["AWS-NoOpAutomationTarget-Value"]
  }
}

# ca-west-1
resource "aws_ssm_association" "ca_west_1_enable_explorer" {
  region = "ca-west-1"

  name             = "AWS-EnableExplorer"
  association_name = "Terraform-SystemAssociationForEnableExplorer"

  schedule_expression = "rate(1 day)"

  targets {
    key    = "aws:NoOpAutomationTag"
    values = ["AWS-NoOpAutomationTarget-Value"]
  }
}

# us-east-1
resource "aws_ssm_association" "us_east_1_enable_explorer" {
  region = "us-east-1"

  name             = "AWS-EnableExplorer"
  association_name = "Terraform-SystemAssociationForEnableExplorer"

  schedule_expression = "rate(1 day)"

  targets {
    key    = "aws:NoOpAutomationTag"
    values = ["AWS-NoOpAutomationTarget-Value"]
  }
}

# us-east-2
resource "aws_ssm_association" "us_east_2_enable_explorer" {
  region = "us-east-2"

  name             = "AWS-EnableExplorer"
  association_name = "Terraform-SystemAssociationForEnableExplorer"

  schedule_expression = "rate(1 day)"

  targets {
    key    = "aws:NoOpAutomationTag"
    values = ["AWS-NoOpAutomationTarget-Value"]
  }
}

# us-west-2
resource "aws_ssm_association" "us_west_2_enable_explorer" {
  region = "us-west-2"

  name             = "AWS-EnableExplorer"
  association_name = "Terraform-SystemAssociationForEnableExplorer"

  schedule_expression = "rate(1 day)"

  targets {
    key    = "aws:NoOpAutomationTag"
    values = ["AWS-NoOpAutomationTarget-Value"]
  }
}
