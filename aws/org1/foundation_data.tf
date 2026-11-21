# Data source to lookup rswea VPC ID from SSM Parameter Store
# This is used to conditionally add aws:Ec2InstanceSourceVpc to CrossAccountAgentRole trust policy

data "aws_ssm_parameter" "rswea_vpc_id" {
  provider = aws.rswea

  name = var.rswea_vpc_id_ssm_parameter_name
}

# Local to determine the VPC ID to use:
# 1. Use var.rswea_vpc_id if explicitly provided
# 2. Otherwise use the SSM lookup value
# 3. If both fail, vpc_id will be empty and condition won't be added
locals {
  rswea_vpc_id = var.rswea_vpc_id != "" ? var.rswea_vpc_id : try(data.aws_ssm_parameter.rswea_vpc_id.value, "")
}
