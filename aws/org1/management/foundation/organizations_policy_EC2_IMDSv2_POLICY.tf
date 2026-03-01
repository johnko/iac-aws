variable "aws_EC2_IMDSv2_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
import {
  to = aws_organizations_policy.EC2_IMDSv2_POLICY
  id = var.aws_EC2_IMDSv2_POLICY
}

resource "aws_organizations_policy" "EC2_IMDSv2_POLICY" {

  name = "IMDSv2"
  type = "DECLARATIVE_POLICY_EC2"

  content = jsonencode({
    "ec2_attributes" : {
      "instance_metadata_defaults" : {
        "http_tokens" : {
          "@@assign" : "required"
        },
        "http_put_response_hop_limit" : {
          "@@assign" : 2
        },
        "http_endpoint" : {
          "@@assign" : "enabled"
        },
        "instance_metadata_tags" : {
          "@@assign" : "no_preference"
        }
      }
    }
  })
}

import {
  to = aws_organizations_policy_attachment.EC2_IMDSv2_POLICY_root
  identity = {
    policy_id = var.aws_EC2_IMDSv2_POLICY
    target_id = aws_organizations_organization.org.roots[0].id
  }
}

resource "aws_organizations_policy_attachment" "EC2_IMDSv2_POLICY_root" {
  policy_id = aws_organizations_policy.EC2_IMDSv2_POLICY.id
  target_id = aws_organizations_organization.org.roots[0].id
}
