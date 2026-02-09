variable "aws_SCP_OnlyOrgIdentityCenter_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
import {
  to = aws_organizations_policy.SCP_OnlyOrgIdentityCenter_POLICY
  id = var.aws_SCP_OnlyOrgIdentityCenter_POLICY
}

resource "aws_organizations_policy" "SCP_OnlyOrgIdentityCenter_POLICY" {

  name        = "OnlyOrgIdentityCenter"
  description = "Denies creating Identity Center at member level since prefer to use it at org level"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "DenyMemberAccountInstances",
        "Effect" : "Deny",
        "Action" : [
          "sso:CreateInstance"
        ],
        "Resource" : "*"
      }
    ]
  })

  tags = {
    "iacdeployer" = "awsconsole"
  }

}

import {
  to = aws_organizations_policy_attachment.SCP_OnlyOrgIdentityCenter_POLICY_root
  identity = {
    policy_id = var.aws_SCP_OnlyOrgIdentityCenter_POLICY
    target_id = aws_organizations_organization.org.roots[0].id
  }
}

resource "aws_organizations_policy_attachment" "SCP_OnlyOrgIdentityCenter_POLICY_root" {
  policy_id = aws_organizations_policy.SCP_OnlyOrgIdentityCenter_POLICY.id
  target_id = aws_organizations_organization.org.roots[0].id
}
