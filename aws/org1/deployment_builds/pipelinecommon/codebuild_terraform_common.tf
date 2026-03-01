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
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ],
        "Resource" : [
          "${aws_s3_bucket.codepipeline.arn}",
          "${aws_s3_bucket.codepipeline.arn}/*"
        ],
        "Effect" : "Allow"
      },
      {
        # See https://docs.aws.amazon.com/codepipeline/latest/userguide/troubleshooting.html#codebuild-role-connections
        "Action" : [
          "codestar-connections:UseConnection"
        ],
        "Resource" : aws_codeconnections_connection.johnko.arn,
        "Effect" : "Allow"
      },
      {
        # Allow write to tfstate bucket
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceAccount" : "${data.aws_caller_identity.current.account_id}"
          }
        },
        "Action" : [
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:ListBucket",
        ],
        "Resource" : [
          "arn:aws:s3:::tfstate-${data.aws_caller_identity.current.account_id}",
          "arn:aws:s3:::tfstate-${data.aws_caller_identity.current.account_id}/*"
        ],
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
          "ssm:GetParameters",
        ],
        "Resource" : [
          "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/TF_VAR_*"
        ],
        "Effect" : "Allow"
      },
      {
        # Read tag policy
        "Action" : [
          "tag:ListRequiredTags",
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
    ]
  })
}
