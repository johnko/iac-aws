locals {
  terraform_common_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceAccount" : "${data.aws_caller_identity.current.account_id}"
          }
        },
        "Action" : [
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket", # To fetch terraform zip
          "s3:PutObject",
        ],
        "Resource" : flatten([
          for k, v in aws_s3_bucket.codepipeline : [v.arn, "${v.arn}/*"]
        ]),
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "s3:PutObject",
        ],
        "Resource" : flatten([
          for k, v in aws_s3_bucket.codepipeline : ["${v.arn}/terraform_*"]
        ]),
        "Effect" : "Deny"
      },
      {
        # See https://docs.aws.amazon.com/codepipeline/latest/userguide/troubleshooting.html#codebuild-role-connections
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceAccount" : "${data.aws_caller_identity.current.account_id}"
          }
        },
        "Action" : [
          "codestar-connections:UseConnection"
        ],
        "Resource" : aws_codeconnections_connection.johnko.arn,
        "Effect" : "Allow"
      },
      {
        # Allow to get SSM Parameter
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceAccount" : "${data.aws_caller_identity.current.account_id}"
          }
        },
        "Action" : [
          "ssm:GetParameter*",
        ],
        "Resource" : [
          "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/TF_VAR_*"
        ],
        "Effect" : "Allow"
      },
      {
        # Read tag policy
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceAccount" : "${data.aws_caller_identity.current.account_id}"
          }
        },
        "Action" : [
          "tag:ListRequiredTags",
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        # Allow to enable/disable the Plan stage transition so Plan doesn't get wiped by next queued execution
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceAccount" : "${data.aws_caller_identity.current.account_id}"
          }
        },
        "Action" : [
          "codepipeline:DisableStageTransition",
          "codepipeline:EnableStageTransition",
        ],
        "Resource" : [
          "arn:aws:codepipeline:*:${data.aws_caller_identity.current.account_id}:TF-*/Plan",
        ],
        "Effect" : "Allow"
      },
    ]
  })
}
