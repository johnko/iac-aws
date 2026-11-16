# SSM Agent Auto Update Configuration
# Creates an SSM Association to automatically update SSM Agent on all instances
# Uses the AWS-UpdateSSMAgent document across all governed regions
# Uses the region argument (supported in AWS provider 6.71.0+)

resource "aws_ssm_association" "ca_central_1_agent_auto_update" {
  name             = "AWS-UpdateSSMAgent"
  association_name = "Terraform-SystemAssociationForSsmAgentUpdate"

  schedule_expression = "rate(14 days)"

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }
}

resource "aws_ssm_association" "ca_west_1_agent_auto_update" {
  region = "ca-west-1"

  name             = "AWS-UpdateSSMAgent"
  association_name = "Terraform-SystemAssociationForSsmAgentUpdate"

  schedule_expression = "rate(14 days)"

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }
}

resource "aws_ssm_association" "us_east_1_agent_auto_update" {
  region = "us-east-1"

  name             = "AWS-UpdateSSMAgent"
  association_name = "Terraform-SystemAssociationForSsmAgentUpdate"

  schedule_expression = "rate(14 days)"

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }
}

resource "aws_ssm_association" "us_east_2_agent_auto_update" {
  region = "us-east-2"

  name             = "AWS-UpdateSSMAgent"
  association_name = "Terraform-SystemAssociationForSsmAgentUpdate"

  schedule_expression = "rate(14 days)"

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }
}

resource "aws_ssm_association" "us_west_2_agent_auto_update" {
  region = "us-west-2"

  name             = "AWS-UpdateSSMAgent"
  association_name = "Terraform-SystemAssociationForSsmAgentUpdate"

  schedule_expression = "rate(14 days)"

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }
}
