provider "aws" {
  allowed_account_ids = [
    var.aws_account_id_sandbox_bedrock
  ]

  default_tags {
    tags = {
      "iacdeployer" = "terraform"
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
