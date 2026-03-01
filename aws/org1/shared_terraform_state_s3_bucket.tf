resource "aws_s3_bucket" "terraform_state" {
  bucket = "tfstate-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# resource "aws_s3_bucket_acl" "terraform_state_acl" {
#   bucket = aws_s3_bucket.terraform_state.id
#   acl    = "private"

#   depends_on = [
#     aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership
#   ]
# }

resource "aws_s3_bucket_versioning" "s3_bucket_version" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_access" {
  bucket                  = aws_s3_bucket.terraform_state.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  skip_destroy = true
}

resource "aws_s3_bucket_request_payment_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.bucket
  payer  = "Requester"
}
