data "aws_ssoadmin_instances" "sso" {}

data "aws_organizations_account" "management" {
  account_id = var.aws_account_id_management
}

locals {
  aws_kms_key_identitycenter_arns = [
    aws_kms_key.identitycenter_primary.arn,
    aws_kms_replica_key.identitycenter_replica.arn,
  ]
}
