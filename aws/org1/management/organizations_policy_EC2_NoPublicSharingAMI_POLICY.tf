variable "aws_EC2_NoPublicSharingAMI_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
import {
  to = aws_organizations_policy.EC2_NoPublicSharingAMI_POLICY
  id = var.aws_EC2_NoPublicSharingAMI_POLICY
}

resource "aws_organizations_policy" "EC2_NoPublicSharingAMI_POLICY" {

  name = "NoPublicSharingAMI"
  type = "DECLARATIVE_POLICY_EC2"

  content = jsonencode({
    "ec2_attributes" : {
      "image_block_public_access" : {
        "state" : {
          "@@assign" : "block_new_sharing"
        }
      }
    }
  })

  tags = {
    "iacdeployer" = "awsconsole"
  }

}

import {
  to = aws_organizations_policy_attachment.EC2_NoPublicSharingAMI_POLICY_root
  identity = {
    policy_id = var.aws_EC2_NoPublicSharingAMI_POLICY
    target_id = aws_organizations_organization.org.roots[0].id
  }
}

resource "aws_organizations_policy_attachment" "EC2_NoPublicSharingAMI_POLICY_root" {
  policy_id = aws_organizations_policy.EC2_NoPublicSharingAMI_POLICY.id
  target_id = aws_organizations_organization.org.roots[0].id
}
