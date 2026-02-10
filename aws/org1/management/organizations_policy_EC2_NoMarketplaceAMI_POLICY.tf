variable "aws_EC2_NoMarketplaceAMI_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
import {
  to = aws_organizations_policy.EC2_NoMarketplaceAMI_POLICY
  id = var.aws_EC2_NoMarketplaceAMI_POLICY
}

resource "aws_organizations_policy" "EC2_NoMarketplaceAMI_POLICY" {

  name = "NoMarketplaceAMI"
  type = "DECLARATIVE_POLICY_EC2"

  content = jsonencode({
    "ec2_attributes" : {
      "allowed_images_settings" : {
        "state" : {
          "@@assign" : "enabled"
        },
        "image_criteria" : {
          "criteria_1" : {
            "allowed_image_providers" : {
              "@@assign" : [
                "amazon",
                "aws_backup_vault"
              ]
            }
          }
        }
      }
    }
  })

  tags = {
    "iacdeployer" = "terraform"
  }

}

import {
  to = aws_organizations_policy_attachment.EC2_NoMarketplaceAMI_POLICY_root
  identity = {
    policy_id = var.aws_EC2_NoMarketplaceAMI_POLICY
    target_id = aws_organizations_organization.org.roots[0].id
  }
}

resource "aws_organizations_policy_attachment" "EC2_NoMarketplaceAMI_POLICY_root" {
  policy_id = aws_organizations_policy.EC2_NoMarketplaceAMI_POLICY.id
  target_id = aws_organizations_organization.org.roots[0].id
}
