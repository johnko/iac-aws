variable "aws_EC2_NoSerial_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
import {
  to = aws_organizations_policy.EC2_NoSerial_POLICY
  id = var.aws_EC2_NoSerial_POLICY
}

resource "aws_organizations_policy" "EC2_NoSerial_POLICY" {

  name = "NoSerial"
  type = "DECLARATIVE_POLICY_EC2"

  content = jsonencode({
    "ec2_attributes" : {
      "serial_console_access" : {
        "status" : {
          "@@assign" : "disabled"
        }
      }
    }
  })

  tags = {
    "iacdeployer" = "terraform"
  }

}

import {
  to = aws_organizations_policy_attachment.EC2_NoSerial_POLICY_root
  identity = {
    policy_id = var.aws_EC2_NoSerial_POLICY
    target_id = aws_organizations_organization.org.roots[0].id
  }
}

resource "aws_organizations_policy_attachment" "EC2_NoSerial_POLICY_root" {
  policy_id = aws_organizations_policy.EC2_NoSerial_POLICY.id
  target_id = aws_organizations_organization.org.roots[0].id
}
