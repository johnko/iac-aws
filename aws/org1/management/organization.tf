variable "aws_org_id" {
  type        = string
  description = "Organization ID, eg. o-abc123"
}

import {
  to = aws_organizations_organization.org
  identity = {
    id = var.aws_org_id
  }
}

resource "aws_organizations_organization" "org" {

  aws_service_access_principals = [
    "account.amazonaws.com",
    "backup.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "controltower.amazonaws.com",
    "cost-optimization-hub.bcm.amazonaws.com",
    "ec2.amazonaws.com",
    "iam.amazonaws.com",
    "member.org.stacksets.cloudformation.amazonaws.com",
    "notifications.amazonaws.com",
    "resource-explorer-2.amazonaws.com",
    "ssm-quicksetup.amazonaws.com",
    "ssm.amazonaws.com",
    "sso.amazonaws.com",
  ]

  enabled_policy_types = [
    "AISERVICES_OPT_OUT_POLICY",
    "BACKUP_POLICY",
    "BEDROCK_POLICY",
    "CHATBOT_POLICY",
    "DECLARATIVE_POLICY_EC2",
    "RESOURCE_CONTROL_POLICY",
    "S3_POLICY",
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
  ]

  feature_set = "ALL"

}
