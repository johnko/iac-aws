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

  bucket = aws_s3_bucket.terraform_state_replica[each.key].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# resource "aws_s3_bucket_acl" "terraform_state_replica" {
#   for_each = local.tfstate_replica_regions

#   bucket = aws_s3_bucket.terraform_state_replica[each.key].id
#   acl    = "private"

#   depends_on = [
#     aws_s3_bucket_ownership_controls.terraform_state_replica
#   ]
# }

resource "aws_s3_bucket_versioning" "terraform_state_replica" {
  for_each = local.tfstate_replica_regions

  bucket = aws_s3_bucket.terraform_state_replica[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_replica" {
  for_each = local.tfstate_replica_regions

  bucket                  = aws_s3_bucket.terraform_state_replica[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  skip_destroy = true
}

resource "aws_s3_bucket_request_payment_configuration" "terraform_state_replica" {
  for_each = local.tfstate_replica_regions

  bucket = aws_s3_bucket.terraform_state_replica[each.key].id
  payer  = "Requester"
}
