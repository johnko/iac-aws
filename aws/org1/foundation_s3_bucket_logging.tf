module "logging" {
  source = "../../../../modules/s3-logging"

  for_each = {
    for v in local.governedRegions : v => {}
  }

  bucket_full_name = format("logging-%s-%s-an", data.aws_caller_identity.current.account_id, each.key)
  bucket_namespace = "account-regional"
  region           = each.key
}
