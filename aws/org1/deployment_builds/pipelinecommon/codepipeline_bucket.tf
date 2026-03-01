resource "aws_s3_bucket" "codepipeline" {
  bucket = "codepipeline-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_ownership_controls" "codepipeline" {
  bucket = aws_s3_bucket.codepipeline.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# resource "aws_s3_bucket_acl" "codepipeline" {
#   bucket = aws_s3_bucket.codepipeline.id
#   acl    = "private"

#   depends_on = [
#     aws_s3_bucket_ownership_controls.codepipeline
#   ]
# }

# resource "aws_s3_bucket_versioning" "codepipeline" {
#   bucket = aws_s3_bucket.codepipeline.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

resource "aws_s3_bucket_public_access_block" "codepipeline" {
  bucket                  = aws_s3_bucket.codepipeline.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  skip_destroy = true
}

# resource "aws_s3_bucket_request_payment_configuration" "codepipeline" {
#   bucket = aws_s3_bucket.codepipeline.bucket
#   payer  = "Requester"
# }

resource "aws_s3_bucket_policy" "codepipeline" {
  bucket = aws_s3_bucket.codepipeline.id
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
          "${aws_s3_bucket.codepipeline.arn}",
          "${aws_s3_bucket.codepipeline.arn}/*"
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

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline" {
  bucket = aws_s3_bucket.codepipeline.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}
