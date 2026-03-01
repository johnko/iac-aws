variable "aws_email_deployment_builds" {
  type        = string
  description = "Email address for the aws account"
}
import {
  to = aws_organizations_account.deployment_account["prod_builds"]
  id = var.aws_account_id_deployment_builds
}

locals {
  deployment_accounts = {
    prod_builds = {
      name  = "DeploymentBuilds"
      email = var.aws_email_deployment_builds
    }
  }
}

resource "aws_organizations_account" "deployment_account" {
  for_each = local.deployment_accounts

  name  = each.value.name
  email = each.value.email

  parent_id = aws_organizations_organizational_unit.ou["deployment"].id

  close_on_deletion = true

  lifecycle {
    ignore_changes = [
      parent_id,
    ]
  }
}
