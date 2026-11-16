# SSM Quick Setup - Gather Software Inventory Configuration
# Creates an SSM Association for AWS-GatherSoftwareInventory
# This association runs every 12 hours to collect software inventory from all instances
# Uses the region argument (supported in AWS provider 6.71.0+)

locals {
  # List of governed regions where this association should be applied
  ssm_inventory_regions = ["ca-central-1", "ca-west-1", "us-east-1", "us-east-2", "us-west-2"]
}

# ca-central-1 (default region - no region argument needed)
resource "aws_ssm_association" "ca_central_1_inventory" {
  name             = "AWS-GatherSoftwareInventory"
  association_name = "Terraform-SystemAssociationForInventory"

  schedule_expression = "rate(12 hours)"

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }
}

# ca-west-1
resource "aws_ssm_association" "ca_west_1_inventory" {
  region = "ca-west-1"

  name             = "AWS-GatherSoftwareInventory"
  association_name = "Terraform-SystemAssociationForInventory"

  schedule_expression = "rate(12 hours)"

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }
}

# us-east-1
resource "aws_ssm_association" "us_east_1_inventory" {
  region = "us-east-1"

  name             = "AWS-GatherSoftwareInventory"
  association_name = "Terraform-SystemAssociationForInventory"

  schedule_expression = "rate(12 hours)"

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }
}

# us-east-2
resource "aws_ssm_association" "us_east_2_inventory" {
  region = "us-east-2"

  name             = "AWS-GatherSoftwareInventory"
  association_name = "Terraform-SystemAssociationForInventory"

  schedule_expression = "rate(12 hours)"

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }
}

# us-west-2
resource "aws_ssm_association" "us_west_2_inventory" {
  region = "us-west-2"

  name             = "AWS-GatherSoftwareInventory"
  association_name = "Terraform-SystemAssociationForInventory"

  schedule_expression = "rate(12 hours)"

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }
}
