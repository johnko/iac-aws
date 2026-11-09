locals {
  cdk_common_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceAccount" : "${data.aws_caller_identity.current.account_id}"
          }
        },
        "Action" : [
          "s3:GetBucketAcl",      # default
          "s3:GetBucketLocation", # default + To fetch terraform zip
          "s3:GetObject",         # default
          "s3:GetObjectVersion",  # default
          "s3:ListBucket",        # To fetch terraform zip
          "s3:PutObject",         # default
        ],
        "Resource" : flatten([
          for k, v in data.aws_s3_bucket.s3_codepipeline : [
            v.arn,
            "${v.arn}/*",
          ]
        ]),
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "s3:PutObject",
        ],
        "Resource" : flatten([
          for k, v in data.aws_s3_bucket.s3_codepipeline : [
            "${v.arn}/terraform_*",
          ]
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
          "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/rswea/*",
          "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/TF_VAR_*",
        ],
        "Effect" : "Allow"
      },
      {
        # Stage Transition Pattern:
        # When a codepipeline execution fails (e.g., approval rejected), the next
        # queued execution will start and disable the inbound transition to the
        # Diff stage. This would wipe the Diff output before users can review it.
        # To prevent this, we grant permissions to re-enable the transition.
        # See lambda/cdk_codepipeline_rejected.py for the handler logic.
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
          "arn:aws:codepipeline:*:${data.aws_caller_identity.current.account_id}:CDK-*/Diff",
        ],
        "Effect" : "Allow"
      },
    ]
  })
}
