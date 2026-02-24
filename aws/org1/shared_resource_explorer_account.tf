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

resource "aws_resourceexplorer2_index" "unusedRegions" {
  for_each = {
    for region in local.unusedRegions : region => {
      "region" : region,
      "type" : region == "ca-central-1" ? "AGGREGATOR" : "LOCAL"
    }
  }

  region = each.value.region
  type   = each.value.type
}
