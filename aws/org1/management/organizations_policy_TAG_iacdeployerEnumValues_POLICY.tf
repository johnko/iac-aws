variable "aws_TAG_iacdeployerEnumValues_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
import {
  to = aws_organizations_policy.TAG_iacdeployerEnumValues_POLICY
  id = var.aws_TAG_iacdeployerEnumValues_POLICY
}

resource "aws_organizations_policy" "TAG_iacdeployerEnumValues_POLICY" {

  name        = "iacdeployerEnumValues"
  description = "Limit iacdeployer values"
  type        = "TAG_POLICY"

  content = jsonencode({
    "tags" : {
      "iacdeployer" : {
        "tag_value" : {
          "@@assign" : [
            "awsautomatic",
            "awscli",
            "awsconsole",
            "cloudformation",
            "pulumi",
            "terraform"
          ]
        }
      }
    }
  })

  tags = {
    "iacdeployer" = "terraform"
  }

}

import {
  to = aws_organizations_policy_attachment.TAG_iacdeployerEnumValues_POLICY_root
  identity = {
    policy_id = var.aws_TAG_iacdeployerEnumValues_POLICY
    target_id = aws_organizations_organization.org.roots[0].id
  }
}

resource "aws_organizations_policy_attachment" "TAG_iacdeployerEnumValues_POLICY_root" {
  policy_id = aws_organizations_policy.TAG_iacdeployerEnumValues_POLICY.id
  target_id = aws_organizations_organization.org.roots[0].id
}
