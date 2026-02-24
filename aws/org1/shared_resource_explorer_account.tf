resource "aws_resourceexplorer2_index" "account" {
  for_each = {
    for region in local.governedRegions : region => {
      "region" : region,
      "type" : region == "ca-central-1" ? "AGGREGATOR" : "LOCAL"
    }
  }

  region = each.value.region
  type   = each.value.type
}

data "aws_caller_identity" "current" {}

locals {
  resourceExplorerAccountWithoutUnusedRegions = [
    var.aws_account_id_security_aggregator,
    var.aws_account_id_security_cloudtrail,
  ]
}

resource "aws_resourceexplorer2_index" "unusedRegions" {
  for_each = {
    for region in local.unusedRegions : region => {
      "region" : region,
      "type" : region == "ca-central-1" ? "AGGREGATOR" : "LOCAL"
    } if contains(local.resourceExplorerAccountWithoutUnusedRegions, data.aws_caller_identity.current.account_id)
  }

  region = each.value.region
  type   = each.value.type
}
