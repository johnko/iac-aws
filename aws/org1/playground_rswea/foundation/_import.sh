#!/usr/bin/env bash
set -euxo pipefail

# Import EC2 Default Host Management for us-east-2 if it already exists
# This is idempotent - it will skip if the resource is already in state
terraform import aws_ssm_service_setting.us_east_2_default_host_management "/ssm/managed-instance/default-ec2-instance-management-role" 2>/dev/null || echo "Resource already exists in state or does not exist in AWS"
