variable "aws_ou_id_security" {
  type        = string
  description = "Organizational Unit ID, eg. ou-xyz789"
}
import {
  to = aws_organizations_organizational_unit.ou["security"]
  identity = {
    id = var.aws_ou_id_security
  }
}

variable "aws_ou_id_sandbox" {
  type        = string
  description = "Organizational Unit ID, eg. ou-xyz789"
}
import {
  to = aws_organizations_organizational_unit.ou["sandbox"]
  identity = {
    id = var.aws_ou_id_sandbox
  }
}

variable "aws_ou_id_quarantine" {
  type        = string
  description = "Organizational Unit ID, eg. ou-xyz789"
}
import {
  to = aws_organizations_organizational_unit.ou["quarantine"]
  identity = {
    id = var.aws_ou_id_quarantine
  }
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
    quarantine = {
      name      = "Quarantine"
      parent_id = aws_organizations_organization.org.roots[0].id
    }
  }
}

resource "aws_organizations_organizational_unit" "ou" {
  for_each = local.ou

  name      = each.value.name
  parent_id = each.value.parent_id

}
