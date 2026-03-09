resource "aws_s3_bucket" "terraform_state" {
  bucket = "tfstate-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_ownership_controls" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# resource "aws_s3_bucket_acl" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id
#   acl    = "private"

#   depends_on = [
#     aws_s3_bucket_ownership_controls.terraform_state
#   ]
# }

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  skip_destroy = true
}

resource "aws_s3_bucket_request_payment_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  payer  = "Requester"
}

########################################

resource "aws_s3_bucket" "terraform_state_replica" {
  for_each = local.tfstate_replica_regions

  region = each.key

  bucket = "tfstate-${data.aws_caller_identity.current.account_id}-${replace(each.key, "-", "")}"
}

resource "aws_s3_bucket_ownership_controls" "terraform_state_replica" {
  for_each = local.tfstate_replica_regions

  region = each.key

  bucket = aws_s3_bucket.terraform_state_replica[each.key].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# resource "aws_s3_bucket_acl" "terraform_state_replica" {
#   for_each = local.tfstate_replica_regions

#   region = each.key

#   bucket = aws_s3_bucket.terraform_state_replica[each.key].id
#   acl    = "private"

#   depends_on = [
#     aws_s3_bucket_ownership_controls.terraform_state_replica
#   ]
# }

resource "aws_s3_bucket_versioning" "terraform_state_replica" {
  for_each = local.tfstate_replica_regions

  region = each.key

  bucket = aws_s3_bucket.terraform_state_replica[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_replica" {
  for_each = local.tfstate_replica_regions

  region = each.key

  bucket                  = aws_s3_bucket.terraform_state_replica[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  skip_destroy = true
}

resource "aws_s3_bucket_request_payment_configuration" "terraform_state_replica" {
  for_each = local.tfstate_replica_regions

  region = each.key

  bucket = aws_s3_bucket.terraform_state_replica[each.key].id
  payer  = "Requester"
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
          aws_s3_bucket.terraform_state.arn,
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
          "${aws_s3_bucket.terraform_state.arn}/*"
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
          for k, v in aws_s3_bucket.terraform_state_replica : [
            "${v.arn}/*"
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
  depends_on = [aws_s3_bucket_versioning.terraform_state]

  role   = aws_iam_role.S3ReplicationRole-tfstate.arn
  bucket = aws_s3_bucket.terraform_state.id

  dynamic "rule" {
    for_each = local.tfstate_replica_regions
    content {
      id = "to ${rule.key}"

      destination {
        bucket = aws_s3_bucket.terraform_state_replica[rule.key].arn
        storage_class = "STANDARD"
      }

      status = "Disabled" # rule.value["replication_enabled"] ? "Enabled" : "Disabled"
    }
  }
}
