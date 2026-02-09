variable "aws_ou_id_security" {
  type        = string
  description = "Organizational Unit ID, eg. ou-xyz789"
}
variable "aws_ou_id_sandbox" {
  type        = string
  description = "Organizational Unit ID, eg. ou-xyz789"
}

locals {
  ou = {
    security = {
      name      = "Security"
      parent_id = aws_organizations_organization.org.roots[0].id
    }
    sandbox = {
      name      = "Sandbox"
      parent_id = aws_organizations_organization.org.roots[0].id
    }
  }
}

import {
  to = aws_organizations_organizational_unit.ou["security"]
  identity = {
    id = var.aws_ou_id_security
  }
}
import {
  to = aws_organizations_organizational_unit.ou["sandbox"]
  identity = {
    id = var.aws_ou_id_sandbox
  }
}

resource "aws_organizations_organizational_unit" "ou" {
  for_each = local.ou

  name      = each.value.name
  parent_id = each.value.parent_id

}
