module "codepipeline" {
  source = "../../../../modules/s3-codepipeline"

  for_each = local.codebuild_suffix_by_region

  bucket_full_name = format("codepipeline-%s-%s-an", data.aws_caller_identity.current.account_id, each.key)
  bucket_namespace = "account-regional"
  region           = each.key
}

#############

resource "aws_s3_bucket" "codepipeline" {
  for_each = local.codebuild_suffix_by_region

  region = each.key

  bucket = "codepipeline-${data.aws_caller_identity.current.account_id}-${replace(each.key, "-", "")}"
}

resource "aws_s3_bucket_ownership_controls" "codepipeline" {
  for_each = local.codebuild_suffix_by_region

  region = each.key

  bucket = aws_s3_bucket.codepipeline[each.key].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "codepipeline" {
  for_each = local.codebuild_suffix_by_region

  region = each.key

  bucket                  = aws_s3_bucket.codepipeline[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  skip_destroy = true
}

resource "aws_s3_bucket_policy" "codepipeline" {
  for_each = local.codebuild_suffix_by_region

  region = each.key

  bucket = aws_s3_bucket.codepipeline[each.key].id
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
          aws_s3_bucket.codepipeline[each.key].arn,
          "${aws_s3_bucket.codepipeline[each.key].arn}/*"
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
