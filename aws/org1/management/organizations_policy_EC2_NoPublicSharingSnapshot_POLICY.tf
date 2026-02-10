variable "aws_EC2_NoPublicSharingSnapshot_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
import {
  to = aws_organizations_policy.EC2_NoPublicSharingSnapshot_POLICY
  id = var.aws_EC2_NoPublicSharingSnapshot_POLICY
}

resource "aws_organizations_policy" "EC2_NoPublicSharingSnapshot_POLICY" {

  name = "NoPublicSharingSnapshot"
  type = "DECLARATIVE_POLICY_EC2"

  content = jsonencode({
    "ec2_attributes" : {
      "snapshot_block_public_access" : {
        "state" : {
          "@@assign" : "block_all_sharing"
        }
      }
    }
  })

  tags = {
    "iacdeployer" = "terraform"
  }

}

import {
  to = aws_organizations_policy_attachment.EC2_NoPublicSharingSnapshot_POLICY_root
  identity = {
    policy_id = var.aws_EC2_NoPublicSharingSnapshot_POLICY
    target_id = aws_organizations_organization.org.roots[0].id
  }
}

resource "aws_organizations_policy_attachment" "EC2_NoPublicSharingSnapshot_POLICY_root" {
  policy_id = aws_organizations_policy.EC2_NoPublicSharingSnapshot_POLICY.id
  target_id = aws_organizations_organization.org.roots[0].id
}
