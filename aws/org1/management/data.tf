data "aws_ssoadmin_instances" "sso" {}

variable "aws_account_id_management" {
  type        = string
  description = "AWS Account ID, eg. 111111111111"
}

data "aws_organizations_account" "management" {
  account_id = var.aws_account_id_management
}

variable "aws_account_id_sandboxbedrock" {
  type        = string
  description = "AWS Account ID, eg. 111111111111"
}

data "aws_organizations_account" "sandboxbedrock" {
  account_id = var.aws_account_id_sandboxbedrock
}
