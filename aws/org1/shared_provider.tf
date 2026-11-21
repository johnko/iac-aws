provider "aws" {
  allowed_account_ids = [
    var.aws_account_id
  ]

  default_tags {
    tags = {
      iacdeployer = "terraform"
    }
  }

  ignore_tags {
    keys = [
      "example_ignored_tag",
    ]
  }

  region = "ca-central-1"

  tag_policy_compliance = "error"
}

# Provider for accessing rswea account resources (SSM parameters)
# Used to lookup the VPC ID for CrossAccountAgentRole security
# Note: SSM parameters are stored in us-east-2 where rswea is deployed
provider "aws" {
  alias = "rswea"

  allowed_account_ids = [
    var.aws_account_id_playground_rswea
  ]

  default_tags {
    tags = {
      iacdeployer = "terraform"
    }
  }

  region = "us-east-2"

  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id_playground_rswea}:role/CrossAccountPipelineRole-TerraformPlan"
  }
}
