variable "aws_EC2_NoIngressVPC_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
import {
  to = aws_organizations_policy.EC2_NoIngressVPC_POLICY
  id = var.aws_EC2_NoIngressVPC_POLICY
}

resource "aws_organizations_policy" "EC2_NoIngressVPC_POLICY" {

  name = "NoIngressVPC"
  type = "DECLARATIVE_POLICY_EC2"

  content = jsonencode({
    "ec2_attributes" : {
      "vpc_block_public_access" : {
        "internet_gateway_block" : {
          "mode" : {
            "@@assign" : "block_ingress"
          },
          "exclusions_allowed" : {
            "@@assign" : "enabled"
          }
        }
      }
    }
  })

  tags = {
    "iacdeployer" = "awsconsole"
  }

}

import {
  to = aws_organizations_policy_attachment.EC2_NoIngressVPC_POLICY_root
  identity = {
    policy_id = var.aws_EC2_NoIngressVPC_POLICY
    target_id = aws_organizations_organization.org.roots[0].id
  }
}

resource "aws_organizations_policy_attachment" "EC2_NoIngressVPC_POLICY_root" {
  policy_id = aws_organizations_policy.EC2_NoIngressVPC_POLICY.id
  target_id = aws_organizations_organization.org.roots[0].id
}
