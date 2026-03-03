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

import {
  to = aws_organizations_organizational_unit.ou["quarantine"]
  identity = {
    id = var.aws_ou_id_quarantine
  }
}

import {
  to = aws_organizations_organizational_unit.ou["deployment"]
  identity = {
    id = var.aws_ou_id_deployment
  }
}

locals {
  # Reference: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_ous_best_practices.html
  ou = {
    deployment = {
      name      = "Deployment"
      parent_id = aws_organizations_organization.org.roots[0].id
    }
    quarantine = {
      name      = "Quarantine"
      parent_id = aws_organizations_organization.org.roots[0].id
    }
    sandbox = {
      name      = "Sandbox"
      parent_id = aws_organizations_organization.org.roots[0].id
    }
    security = {
      name      = "Security"
      parent_id = aws_organizations_organization.org.roots[0].id
    }
  }
}

resource "aws_organizations_organizational_unit" "ou" {
  for_each = local.ou

  name      = each.value.name
  parent_id = each.value.parent_id

}
