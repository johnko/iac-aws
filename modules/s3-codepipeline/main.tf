resource "aws_s3_bucket" "bucket" {
  region = var.region

  bucket = var.bucket_full_name
  bucket_namespace = var.bucket_namespace

  lifecycle {
    ignore_changes = [
      policy,
    ]
  }
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

# resource "aws_s3_bucket_request_payment_configuration" "bucket" {
#   region = var.region

#   bucket = aws_s3_bucket.bucket.id
#   payer  = "Requester"
# }

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  region = var.region

  bucket = aws_s3_bucket.bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_policy" "bucket" {
  region = var.region

  bucket = aws_s3_bucket.bucket.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Deny",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : "s3:*",
        "Resource" : [
          aws_s3_bucket.bucket.arn,
          "${aws_s3_bucket.bucket.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      }
    ]
  })
}
