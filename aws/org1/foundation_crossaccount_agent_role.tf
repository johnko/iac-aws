resource "aws_iam_role" "crossaccount_agent" {
  name = "CrossAccountAgentRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${var.aws_account_id_playground_rswea}:root"
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "StringEquals" : {
            "aws:PrincipalOrgID" : data.aws_organizations_organization.current.id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "crossaccount_agent" {
  role_name = aws_iam_role.crossaccount_agent.name
  policy_arns = [
    "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess", # ViewOnly avoids reading sensitive data like Secrets or S3
  ]
}

locals {
  crossaccount_inline_policies_agent = {
    # Grant troubleshooting permissions from createTroubleshootingPolicyStatement
    TroubleshootingPolicyStatement = {
      enabled_aws_account_ids = keys(local.all_aws_account_ids)
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Action" : [
              "bedrock:ListFoundationModels",
              "ce:GetCostAndUsage",
              "ce:GetCostForecast",
              "ce:GetUsageForecast",
              "cloudformation:ContinueUpdateRollback",
              "cloudformation:DescribeStackEvents",
              "cloudformation:DescribeStackResource",
              "ecr:DescribeImages",
              "ecr:DescribeRepositories",
              "lambda:GetFunction",
              "lambda:GetFunctionCode",
              "logs:DescribeLogStreams",
              "logs:DescribeLogGroups",
              "logs:GetLogEvents",
              "logs:FilterLogEvents",
              "s3:ListBucket",
              "s3:GetBucketLocation",
              "s3:GetBucketVersioning",
              "ssm:DescribeParameters",
              "ssm:GetServiceSetting",
              "ssm:ListTagsForResource",
            ],
            "Resource" : "*",
            "Effect" : "Allow"
          },
        ]
      })
    }
  }
}

resource "aws_iam_role_policy" "crossaccount_agent" {
  for_each = {
    for k, v in local.crossaccount_inline_policies_agent :
    k => v if contains(v.enabled_aws_account_ids, data.aws_caller_identity.current.account_id)
  }

  name   = each.key
  role   = aws_iam_role.crossaccount_agent.id
  policy = each.value.policy
}

resource "aws_iam_role_policies_exclusive" "crossaccount_agent" {
  role_name    = aws_iam_role.crossaccount_agent.name
  policy_names = keys(aws_iam_role_policy.crossaccount_agent)
}
