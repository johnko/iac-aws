resource "aws_s3_bucket" "bucket" {
  region = var.region

  bucket = var.bucket_full_name
  bucket_namespace = var.bucket_namespace
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  region = var.region

  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# resource "aws_s3_bucket_acl" "bucket" {
#   region = var.region

#   bucket = aws_s3_bucket.bucket.id
#   acl    = "private"

#   depends_on = [
#     aws_s3_bucket_ownership_controls.bucket
#   ]
# }

resource "aws_s3_bucket_versioning" "bucket" {
  region = var.region

  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  region = var.region

  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  skip_destroy = true
}

resource "aws_s3_bucket_request_payment_configuration" "bucket" {
  region = var.region

  bucket = aws_s3_bucket.bucket.id
  payer  = "Requester"
}
