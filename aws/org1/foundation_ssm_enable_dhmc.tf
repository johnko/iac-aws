# SSM Quick Setup - Enable DHMC (Default Host Management Configuration)
# Creates an SSM Association for AWSQuickSetupType-EnableDHMC
# This association runs daily to enable Default Host Management
# Uses the region argument (supported in AWS provider 6.71.0+)

locals {
  # List of governed regions where this association should be applied
  ssm_enable_dhmc_regions = ["ca-central-1", "ca-west-1", "us-east-1", "us-east-2", "us-west-2"]
}

# ca-central-1 (default region - no region argument needed)
resource "aws_ssm_association" "ca_central_1_enable_dhmc" {
  name             = "AWSQuickSetupType-EnableDHMC"
  association_name = "Terraform-SystemAssociationForEnableDHMC"

  schedule_expression = "rate(1 day)"

  targets {
    key    = "aws:NoOpAutomationTag"
    values = ["AWS-NoOpAutomationTarget-Value"]
  }
}

# ca-west-1
resource "aws_ssm_association" "ca_west_1_enable_dhmc" {
  region = "ca-west-1"

  name             = "AWSQuickSetupType-EnableDHMC"
  association_name = "Terraform-SystemAssociationForEnableDHMC"

  schedule_expression = "rate(1 day)"

  targets {
    key    = "aws:NoOpAutomationTag"
    values = ["AWS-NoOpAutomationTarget-Value"]
  }
}

# us-east-1
resource "aws_ssm_association" "us_east_1_enable_dhmc" {
  region = "us-east-1"

  name             = "AWSQuickSetupType-EnableDHMC"
  association_name = "Terraform-SystemAssociationForEnableDHMC"

  schedule_expression = "rate(1 day)"

  targets {
    key    = "aws:NoOpAutomationTag"
    values = ["AWS-NoOpAutomationTarget-Value"]
  }
}

# us-east-2
resource "aws_ssm_association" "us_east_2_enable_dhmc" {
  region = "us-east-2"

  name             = "AWSQuickSetupType-EnableDHMC"
  association_name = "Terraform-SystemAssociationForEnableDHMC"

  schedule_expression = "rate(1 day)"

  targets {
    key    = "aws:NoOpAutomationTag"
    values = ["AWS-NoOpAutomationTarget-Value"]
  }
}

# us-west-2
resource "aws_ssm_association" "us_west_2_enable_dhmc" {
  region = "us-west-2"

  name             = "AWSQuickSetupType-EnableDHMC"
  association_name = "Terraform-SystemAssociationForEnableDHMC"

  schedule_expression = "rate(1 day)"

  targets {
    key    = "aws:NoOpAutomationTag"
    values = ["AWS-NoOpAutomationTarget-Value"]
  }
}
