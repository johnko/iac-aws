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
}
