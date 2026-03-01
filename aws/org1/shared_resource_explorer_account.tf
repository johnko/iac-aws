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
    } if !contains(local.resourceExplorerAccountWithoutUnusedRegions, data.aws_caller_identity.current.account_id)
  }

  region = each.value.region
  type   = each.value.type
}

# Sample query
# region:ca-central-1,ca-west-1,us-east-1,us-east-2,us-west-2 -tag.key:aws:cloudformation:stack-name -tag.value:awsautomatic -tag.value:awsconsole -tag.value:terraform -resourcetype:athena:datacatalog -resourcetype:ec2:security-group-rule -resourcetype:events:rule -resourcetype:memorydb:acl -resourcetype:memorydb:parametergroup -resourcetype:memorydb:user -resourcetype:ssm:resource-data-sync -resourcetype:resource-explorer-2:index

resource "aws_resourceexplorer2_view" "all_resources" {
  name = "all-resources"

  default_view = true

  included_property {
    name = "tags"
  }

  depends_on = [
    aws_resourceexplorer2_index.account,
  ]
}
