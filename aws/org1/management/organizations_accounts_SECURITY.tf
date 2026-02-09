variable "aws_account_id_security_aggregator" {
  type        = string
  description = "AWS Account ID, eg. 111111111111"
}
variable "aws_email_security_aggregator" {
  type        = string
  description = "Email address for the aws account"
}
import {
  to = aws_organizations_account.security_account["security_aggregator"]
  id = var.aws_account_id_security_aggregator
}

variable "aws_account_id_security_cloudtrail" {
  type        = string
  description = "AWS Account ID, eg. 111111111111"
}
variable "aws_email_security_cloudtrail" {
  type        = string
  description = "Email address for the aws account"
}
import {
  to = aws_organizations_account.security_account["security_cloudtrail"]
  id = var.aws_account_id_security_cloudtrail
}

locals {
  security_accounts = {
    security_aggregator = {
      name  = "Aggregator account"
      email = var.aws_email_security_aggregator
    }
    security_cloudtrail = {
      name  = "CloudTrail administrator"
      email = var.aws_email_security_cloudtrail
    }
  }
}

resource "aws_organizations_account" "security_account" {
  for_each = local.security_accounts

  name  = each.value.name
  email = each.value.email

  parent_id = aws_organizations_organizational_unit.ou["security"].id

  close_on_deletion = true

}
