variable "aws_controltower_landingzone_id" {
  type        = string
  description = "AWS ControlTower LandingZone ID, eg. ABCD1234"
}
import {
  to = aws_controltower_landing_zone.org
  id = var.aws_controltower_landingzone_id
}

resource "aws_controltower_landing_zone" "org" {
  version = "4.0"
  manifest_json = jsonencode({
    "accessManagement" : {
      "enabled" : true # Required - Controls IAM Identity Center integration
    },
    "backup" : {
      "enabled" : false, # Required - Controls AWS Backup integration
    },
    "centralizedLogging" : {
      "accountId" : aws_organizations_account.security_account["security_cloudtrail"].id, # Log archive account
      "enabled" : true,                                                                   # Required - Controls centralized logging
      "configurations" : {
        "accessLoggingBucket" : {
          "retentionDays" : 2920
        },
        "loggingBucket" : {
          "retentionDays" : 2920
        },
      }
    },
    "config" : {
      "accountId" : aws_organizations_account.security_account["security_aggregator"].id, # Config aggregator account
      "enabled" : true,                                                                   # Required - Controls AWS Config integration
      "configurations" : {
        "accessLoggingBucket" : {
          "retentionDays" : 2920
        },
        "loggingBucket" : {
          "retentionDays" : 2920
        },
      }
    },
    "governedRegions" : [ # List of regions to govern, order matters to prevent change
      "ca-central-1",
      "us-east-2",
      "us-east-1",
      "ca-west-1"
    ],
    "securityRoles" : {
      "enabled" : true,                                                                  # Required - Controls security roles creation
      "accountId" : aws_organizations_account.security_account["security_aggregator"].id # Security/Audit account
    }
  })
}
