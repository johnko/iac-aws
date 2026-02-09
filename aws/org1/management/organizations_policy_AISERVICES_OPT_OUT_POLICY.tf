variable "policy_id_aiservices_opt_out" {
  type        = string
  description = "Policy ID, eg. p-123"
}
import {
  to = aws_organizations_policy.AISERVICES_OPT_OUT_POLICY
  id = var.policy_id_aiservices_opt_out
}

resource "aws_organizations_policy" "AISERVICES_OPT_OUT_POLICY" {

  name        = "OptOutFromAllAIServices"
  description = "Opt outs from all AI services."
  type        = "AISERVICES_OPT_OUT_POLICY"

  content = jsonencode({
    "services" : {
      "@@operators_allowed_for_child_policies" : [
        "@@none"
      ],
      "default" : {
        "@@operators_allowed_for_child_policies" : [
          "@@none"
        ],
        "opt_out_policy" : {
          "@@operators_allowed_for_child_policies" : [
            "@@none"
          ],
          "@@assign" : "optOut"
        }
      }
    }
  })

  tags = {
    "iacdeployer" = "awsconsole"
  }

}

import {
  to = aws_organizations_policy_attachment.AISERVICES_OPT_OUT_POLICY_root
  identity = {
    policy_id = var.policy_id_aiservices_opt_out
    target_id = aws_organizations_organization.org.roots[0].id
  }
}

resource "aws_organizations_policy_attachment" "AISERVICES_OPT_OUT_POLICY_root" {
  policy_id = aws_organizations_policy.AISERVICES_OPT_OUT_POLICY.id
  target_id = aws_organizations_organization.org.roots[0].id
}
