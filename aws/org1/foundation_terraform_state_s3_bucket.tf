module "terraform_state" {
  source = "../../../modules/s3-private"

  bucket_full_name = format("tfstate-%s-%s-an", data.aws_caller_identity.current.account_id, local.tfstate_primary_region)
  bucket_namespace = "account-regional"
  region           = local.tfstate_primary_region
}

########################################

module "terraform_state_replica" {
  source = "../../../modules/s3-private"

  for_each = local.tfstate_replica_regions

  bucket_full_name = format("tfstate-%s-%s-an", data.aws_caller_identity.current.account_id, each.key)
  bucket_namespace = "account-regional"
  region           = each.key
}

########################################

resource "aws_iam_role" "S3ReplicationRole-tfstate" {
  name = "S3ReplicationRole-tfstate"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "s3.amazonaws.com"
        },
        "Action" : "sts:AssumeRole",
      }
    ]
  })
}

resource "aws_iam_role_policy" "S3ReplicationRoleDefaultPolicy" {
  name = "S3ReplicationRoleDefaultPolicy"
  role = aws_iam_role.S3ReplicationRole-tfstate.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
        ],
        "Resource" : [
          module.terraform_state.aws_s3_bucket.bucket.arn,
        ],
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
        ],
        "Resource" : [
          "${module.terraform_state.aws_s3_bucket.bucket.arn}/*"
        ],
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
        ],
        "Resource" : flatten([
          for k, v in module.terraform_state_replica : [
            "${v.aws_s3_bucket.bucket.arn}/*"
          ]
        ]),
        "Effect" : "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policies_exclusive" "S3ReplicationRole-tfstate" {
  role_name    = aws_iam_role.S3ReplicationRole-tfstate.name
  policy_names = [aws_iam_role_policy.S3ReplicationRoleDefaultPolicy.name]
}

########################################

resource "aws_s3_bucket_replication_configuration" "terraform_state_replica" {
  # Must have bucket versioning enabled first
  depends_on = [module.terraform_state.aws_s3_bucket_versioning.bucket]

  role   = aws_iam_role.S3ReplicationRole-tfstate.arn
  bucket = module.terraform_state.aws_s3_bucket.bucket.id

  dynamic "rule" {
    # Number of distinct destination bucket ARNs cannot exceed 1
    for_each = {
      for k, v in local.tfstate_replica_regions : k => v if v.replication_enabled
    }
    content {
      id = "to ${rule.key}"

      destination {
        bucket        = module.terraform_state_replica[rule.key].aws_s3_bucket.bucket.arn
        storage_class = "STANDARD"
      }

      status = rule.value["replication_enabled"] ? "Enabled" : "Disabled"
    }
  }
}
