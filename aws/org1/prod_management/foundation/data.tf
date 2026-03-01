data "aws_ssoadmin_instances" "sso" {}

data "aws_organizations_account" "management" {
  account_id = var.aws_account_id_management
}
