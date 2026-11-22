# Local to determine the VPC ID to use:
# 1. Use var.rswea_vpc_id if explicitly provided via TF_VAR_rswea_vpc_id env var
# 2. If empty, the aws:Ec2InstanceSourceVpc condition won't be added
locals {
  rswea_vpc_id = var.rswea_vpc_id
}
