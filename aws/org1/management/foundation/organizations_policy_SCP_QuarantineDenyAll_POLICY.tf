variable "aws_SCP_QuarantineDenyAll_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
import {
  to = aws_organizations_policy.SCP_QuarantineDenyAll_POLICY
  id = var.aws_SCP_QuarantineDenyAll_POLICY
}

resource "aws_organizations_policy" "SCP_QuarantineDenyAll_POLICY" {

  name        = "QuarantineDenyAll"
  description = "Denies all actions"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "DenyAll",
        "Effect" : "Deny",
        "Action" : [
          "*"
        ],
        "Resource" : "*"
      }
    ]
  })
}

import {
  to = aws_organizations_policy_attachment.SCP_QuarantineDenyAll_POLICY_root
  identity = {
    policy_id = var.aws_SCP_QuarantineDenyAll_POLICY
    target_id = aws_organizations_organizational_unit.ou["quarantine"].id
  }
}

resource "aws_organizations_policy_attachment" "SCP_QuarantineDenyAll_POLICY_root" {
  policy_id = aws_organizations_policy.SCP_QuarantineDenyAll_POLICY.id
  target_id = aws_organizations_organizational_unit.ou["quarantine"].id
}
