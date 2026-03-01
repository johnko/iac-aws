resource "aws_kms_key" "identitycenter_primary" {
  description             = "Multi-Region primary key for Identity Center"
  deletion_window_in_days = 30
  multi_region            = true
}
resource "aws_kms_key_policy" "identitycenter_primary" {
  key_id = aws_kms_key.identitycenter_primary.id
  policy = local.identitycenter_kms_key_policy
}

resource "aws_kms_replica_key" "identitycenter_replica" {
  region = "ca-west-1"

  description             = "Multi-Region replica key for Identity Center"
  deletion_window_in_days = 7
  primary_key_arn         = aws_kms_key.identitycenter_primary.arn
}
resource "aws_kms_key_policy" "identitycenter_replica" {
  region = "ca-west-1"

  key_id = aws_kms_key.identitycenter_replica.id
  policy = local.identitycenter_kms_key_policy
}

locals {
  # https://docs.aws.amazon.com/singlesignon/latest/userguide/baseline-KMS-key-policy.html
  identitycenter_kms_key_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      # Default Enable IAM User Permissions
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_organizations_account.management.id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      # Baseline KMS key policy statements for use of IAM Identity Center (required)
      {
        "Sid" : "AllowIAMIdentityCenterAdminToUseTheKMSKeyViaIdentityCenter",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_organizations_account.management.id}:root",
          ]
        },
        "Action" : [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKeyWithoutPlaintext"
        ],
        "Resource" : "*",
        "Condition" : {
          "ArnLike" : {
            "aws:PrincipalArn" : [
              "arn:aws:iam::${data.aws_organizations_account.management.id}:role/aws-reserved/sso.amazonaws.com/us-east-1/AWSReservedSSO_Admin_*",
            ]
          },
          "StringLike" : {
            "kms:EncryptionContext:aws:sso:instance-arn" : "*",
            "kms:ViaService" : "sso.*.amazonaws.com"
          }
        }
      },
      {
        "Sid" : "AllowIAMIdentityCenterAdminToUseTheKMSKeyViaIdentityStore",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_organizations_account.management.id}:root",
          ]
        },
        "Action" : [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKeyWithoutPlaintext"
        ],
        "Resource" : "*",
        "Condition" : {
          "ArnLike" : {
            "aws:PrincipalArn" : [
              "arn:aws:iam::${data.aws_organizations_account.management.id}:role/aws-reserved/sso.amazonaws.com/us-east-1/AWSReservedSSO_Admin_*",
            ]
          },
          "StringLike" : {
            "kms:EncryptionContext:aws:identitystore:identitystore-arn" : "*",
            "kms:ViaService" : "identitystore.*.amazonaws.com"
          }
        }
      },
      {
        "Sid" : "AllowIAMIdentityCenterAdminToDescribeTheKMSKey",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_organizations_account.management.id}:root",
          ]
        },
        "Action" : "kms:DescribeKey",
        "Resource" : "*",
        "Condition" : {
          "ArnLike" : {
            "aws:PrincipalArn" : [
              "arn:aws:iam::${data.aws_organizations_account.management.id}:role/aws-reserved/sso.amazonaws.com/us-east-1/AWSReservedSSO_Admin_*",
            ]
          }
        }
      },
      {
        "Sid" : "AllowIAMIdentityCenterToUseTheKMSKey",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "sso.amazonaws.com"
        },
        "Action" : [
          "kms:Decrypt",
          "kms:ReEncryptTo",
          "kms:ReEncryptFrom",
          "kms:GenerateDataKeyWithoutPlaintext"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "kms:EncryptionContext:aws:sso:instance-arn" : "*"
          },
          "StringEquals" : {
            "aws:SourceAccount" : "${data.aws_organizations_account.management.id}"
          }
        }
      },
      {
        "Sid" : "AllowIdentityStoreToUseTheKMSKey",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "identitystore.amazonaws.com"
        },
        "Action" : [
          "kms:Decrypt",
          "kms:ReEncryptTo",
          "kms:ReEncryptFrom",
          "kms:GenerateDataKeyWithoutPlaintext"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "kms:EncryptionContext:aws:identitystore:identitystore-arn" : "*"
          },
          "StringEquals" : {
            "aws:SourceAccount" : "${data.aws_organizations_account.management.id}"
          }
        }
      },
      {
        "Sid" : "AllowIAMIdentityCenterAndIdentityStoreToDescribeKMSKey",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "identitystore.amazonaws.com",
            "sso.amazonaws.com"
          ]
        },
        "Action" : "kms:DescribeKey",
        "Resource" : "*"
      }
    ]
  })
}
