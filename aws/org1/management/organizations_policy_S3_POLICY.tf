variable "aws_S3_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
import {
  to = aws_organizations_policy.S3_POLICY
  id = var.aws_S3_POLICY
}

resource "aws_organizations_policy" "S3_POLICY" {

  name = "NoPublicAccessS3"
  type = "S3_POLICY"

  content = jsonencode({
    "s3_attributes" : {
      "public_access_block_configuration" : {
        "@@assign" : "all"
      }
    }
  })

  tags = {
    "iacdeployer" = "awsconsole"
  }

}

import {
  to = aws_organizations_policy_attachment.S3_POLICY_root
  identity = {
    policy_id = var.aws_S3_POLICY
    target_id = aws_organizations_organization.org.roots[0].id
  }
}

resource "aws_organizations_policy_attachment" "S3_POLICY_root" {
  policy_id = aws_organizations_policy.S3_POLICY.id
  target_id = aws_organizations_organization.org.roots[0].id
}
