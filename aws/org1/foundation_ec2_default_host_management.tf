# EC2 Default Host Management Configuration
# Enables default EC2 host management for Systems Manager across all governed regions
# Uses the region argument (supported in AWS provider 6.71.0+)

# Import existing service-linked role if it already exists
import {
  to = aws_iam_service_linked_role.ssm_default_host_management
  id = "arn:aws:iam::${var.aws_account_id}:role/aws-service-role/ssm.amazonaws.com/AWSServiceRoleForAmazonSSM"
}

# IAM Service-Linked Role for SSM Default Host Management
# This role is required for the SSM service setting to work
resource "aws_iam_service_linked_role" "ssm_default_host_management" {
  aws_service_name = "ssm.amazonaws.com"
  description      = "Provides access to AWS Resources managed or used by Amazon SSM."

  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_ssm_service_setting" "ca_central_1_default_host_management" {
  setting_id    = "/ssm/managed-instance/default-ec2-instance-management-role"
  setting_value = "service-role/AWSSystemsManagerDefaultEC2InstanceManagementRole"

  depends_on = [aws_iam_service_linked_role.ssm_default_host_management]
}

resource "aws_ssm_service_setting" "ca_west_1_default_host_management" {
  region        = "ca-west-1"
  setting_id    = "/ssm/managed-instance/default-ec2-instance-management-role"
  setting_value = "service-role/AWSSystemsManagerDefaultEC2InstanceManagementRole"

  depends_on = [aws_iam_service_linked_role.ssm_default_host_management]
}

resource "aws_ssm_service_setting" "us_east_1_default_host_management" {
  region        = "us-east-1"
  setting_id    = "/ssm/managed-instance/default-ec2-instance-management-role"
  setting_value = "service-role/AWSSystemsManagerDefaultEC2InstanceManagementRole"

  depends_on = [aws_iam_service_linked_role.ssm_default_host_management]
}

resource "aws_ssm_service_setting" "us_east_2_default_host_management" {
  region        = "us-east-2"
  setting_id    = "/ssm/managed-instance/default-ec2-instance-management-role"
  setting_value = "service-role/AWSSystemsManagerDefaultEC2InstanceManagementRole"

  depends_on = [aws_iam_service_linked_role.ssm_default_host_management]
}

resource "aws_ssm_service_setting" "us_west_2_default_host_management" {
  region        = "us-west-2"
  setting_id    = "/ssm/managed-instance/default-ec2-instance-management-role"
  setting_value = "service-role/AWSSystemsManagerDefaultEC2InstanceManagementRole"

  depends_on = [aws_iam_service_linked_role.ssm_default_host_management]
}
