variable "aws_email_sandbox_bedrock" {
  type        = string
  description = "Email address for the aws account"
}
import {
  to = aws_organizations_account.sandbox_account["sandbox_bedrock"]
  id = var.aws_account_id_sandbox_bedrock
}

locals {
  sandbox_accounts = {
    sandbox_bedrock = {
      name  = "SandboxBedrock"
      email = var.aws_email_sandbox_bedrock
    }
  }
}

resource "aws_organizations_account" "sandbox_account" {
  for_each = local.sandbox_accounts

  name  = each.value.name
  email = each.value.email

  parent_id = aws_organizations_organizational_unit.ou["sandbox"].id

  close_on_deletion = true

  lifecycle {
    ignore_changes = [
      parent_id,
    ]
  }
}
