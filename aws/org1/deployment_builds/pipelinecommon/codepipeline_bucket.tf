module "codepipeline" {
  source = "../../../../modules/s3-codepipeline"

  for_each = local.codebuild_suffix_by_region

  bucket_full_name = format("codepipeline-%s-%s-an", data.aws_caller_identity.current.account_id, each.key)
  bucket_namespace = "account-regional"
  region           = each.key
}
