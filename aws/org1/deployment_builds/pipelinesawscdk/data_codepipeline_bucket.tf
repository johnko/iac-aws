locals {
  # Define the list of S3 bucket names you need to fetch details for
  bucket_names = {
    for k, v in local.codebuild_suffix_by_region :
      format("codepipeline-%s-%s-an", data.aws_caller_identity.current.account_id, k) => {
        region: k
      }
  }
}

output "bucket_names" {
  value = local.bucket_names
}

# Loop through the list of bucket names using for_each
data "aws_s3_bucket" "s3_codepipeline" {
  for_each = local.bucket_names

  bucket = each.key
  region = each.value.region
}
