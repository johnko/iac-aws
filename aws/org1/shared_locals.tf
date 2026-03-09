locals {
  all_aws_account_ids = {
    "${var.aws_account_id_management}"          = {}
    "${var.aws_account_id_security_aggregator}" = {}
    "${var.aws_account_id_security_cloudtrail}" = {}
    "${var.aws_account_id_deployment_builds}"   = {}
    "${var.aws_account_id_sandbox_bedrock}"     = {}
  }

  resourceExplorerAccountWithoutUnusedRegions = [
    # var.aws_account_id_management, # Omit management so we can still gather info about resources in other regions
    var.aws_account_id_security_aggregator,
    var.aws_account_id_security_cloudtrail,
    var.aws_account_id_deployment_builds,
    var.aws_account_id_sandbox_bedrock,
  ]

  governedRegions = [ # List of regions to govern
    ##### ORDER MATTERS TO PREVENT CHANGE
    "ca-central-1",
    "us-east-2", # bedrock cross-region inference profile
    "us-east-1",
    "ca-west-1",
    "us-west-2", # bedrock cross-region inference profile
  ]

  unusedRegions = [
    "ap-northeast-1",
    "ap-northeast-2",
    "ap-northeast-3",
    "ap-south-1",
    "ap-southeast-1",
    "ap-southeast-2",
    "eu-central-1",
    "eu-north-1",
    "eu-west-1",
    "eu-west-2",
    "eu-west-3",
    "sa-east-1",
    "us-west-1",
  ]

  tfstate_replica_regions = {
    "ca-west-1" = {
      replication_enabled = true
    }
    "us-east-2" = {
      replication_enabled = false
    }
  }

  codepipeline_primary_region   = "ca-central-1"
  codepipeline_secondary_region = "us-east-2"

  codebuild_types = {
    container-linux-small = {
      build_timeout   = 60
      compute_type    = "BUILD_GENERAL1_SMALL"
      image           = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
      privileged_mode = true
      queued_timeout  = 90
      region          = local.codepipeline_primary_region
      type            = "LINUX_CONTAINER"
    }
    lambda-linux-1 = {
      build_timeout   = 15
      compute_type    = "BUILD_LAMBDA_1GB"
      image           = "aws/codebuild/amazonlinux-x86_64-lambda-standard:python3.13"
      privileged_mode = false
      queued_timeout  = null
      region          = local.codepipeline_secondary_region
      type            = "LINUX_LAMBDA_CONTAINER"
    }
  }

  codebuild_suffix_by_region = {
    for k, v in local.codebuild_types : v.region => k
  }

  slack_common_policy_statement = {
    codebuild_codepipeline_read = {
      "Action" : [
        "cloudwatch:GetMetricStatistics",
        "codebuild:BatchGet*",
        "codebuild:DescribeCodeCoverages",
        "codebuild:DescribeTestCases",
        "codebuild:GetResourcePolicy",
        "codebuild:List*",
        "codepipeline:GetPipeline",
        "codepipeline:GetPipelineExecution",
        "codepipeline:GetPipelineState",
        "codepipeline:ListActionExecutions",
        "codepipeline:ListActionTypes",
        "codepipeline:ListPipelineExecutions",
        "codepipeline:ListPipelines",
        "codepipeline:ListTagsForResource",
        "events:DescribeRule",
        "events:ListRuleNamesByTarget",
        "events:ListTargetsByRule",
        "s3:ListAllMyBuckets",
      ],
      "Effect" : "Allow",
      "Resource" : "*"
    }
    logs_read = {
      "Action" : [
        "logs:GetLogEvents",
      ],
      "Effect" : "Allow",
      "Resource" : [
        "arn:aws:logs:*:${var.aws_account_id_deployment_builds}:log-group:/aws/codebuild/Terraform*",
        "arn:aws:logs:*:${var.aws_account_id_deployment_builds}:log-group:/aws/codepipeline/TF-*",
        "arn:aws:logs:*:${var.aws_account_id_deployment_builds}:log-group:/aws/lambda/Terraform*",
      ]
    }
  }

  slack_user_roles = {
    "viewer" = {
      inline_policy1 = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          local.slack_common_policy_statement["codebuild_codepipeline_read"],
          local.slack_common_policy_statement["logs_read"],
        ]
      })
    }
    "approver" = {
      inline_policy1 = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Action" : [
              "codepipeline:PutApprovalResult",
            ],
            "Effect" : "Allow",
            "Resource" : "*"
          },
          local.slack_common_policy_statement["codebuild_codepipeline_read"],
          local.slack_common_policy_statement["logs_read"],
        ]
      })
    }
    "invoker" = {}
  }
}

data "aws_caller_identity" "current" {}
