import {
  to = aws_organizations_account.playground_account["playground_rswea"]
  id = var.aws_account_id_playground_rswea
}

locals {
  playground_accounts = {
    playground_rswea = {
      name  = "PlaygroundRSWEA"
      email = var.aws_email_playground_rswea
    }
  }
}

resource "aws_organizations_account" "playground_account" {
  for_each = local.playground_accounts

  name  = each.value.name
  email = each.value.email

  parent_id = aws_organizations_organizational_unit.ou["playground"].id

  close_on_deletion = true

  lifecycle {
    ignore_changes = [
      parent_id,
    ]
  }
}
