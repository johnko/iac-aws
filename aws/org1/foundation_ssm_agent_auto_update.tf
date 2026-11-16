# SSM Agent Auto Update Configuration
# Enables automatic updates of SSM Agent across all governed regions
# Uses the region argument (supported in AWS provider 6.71.0+)

resource "aws_ssm_service_setting" "ca_central_1_agent_auto_update" {
  setting_id    = "/ssm/managed-instance-automatic-update"
  setting_value = "Enabled"
}

resource "aws_ssm_service_setting" "ca_west_1_agent_auto_update" {
  region        = "ca-west-1"
  setting_id    = "/ssm/managed-instance-automatic-update"
  setting_value = "Enabled"
}

resource "aws_ssm_service_setting" "us_east_1_agent_auto_update" {
  region        = "us-east-1"
  setting_id    = "/ssm/managed-instance-automatic-update"
  setting_value = "Enabled"
}

resource "aws_ssm_service_setting" "us_east_2_agent_auto_update" {
  region        = "us-east-2"
  setting_id    = "/ssm/managed-instance-automatic-update"
  setting_value = "Enabled"
}

resource "aws_ssm_service_setting" "us_west_2_agent_auto_update" {
  region        = "us-west-2"
  setting_id    = "/ssm/managed-instance-automatic-update"
  setting_value = "Enabled"
}
