resource "aws_resourceexplorer2_index" "org" {
  for_each = {
    for region in local.unusedRegions : region => {
      "region" : region,
      "type" : region == "ca-central-1" ? "AGGREGATOR" : "LOCAL"
    }
  }

  region = each.value.region
  type   = each.value.type
}
