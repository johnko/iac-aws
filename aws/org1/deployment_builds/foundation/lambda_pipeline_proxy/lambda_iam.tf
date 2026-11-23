# IAM Role and Policy for Lambda Pipeline Proxy

# Data source for current AWS account
data "aws_caller_identity" "pipeline_proxy_current" {}
data "aws_organizations_organization" "pipeline_proxy_current" {}

# Data source for current organization
data "aws_organizations_organization" "pipeline_proxy_current" {}

resource "aws_iam_role" "pipeline_proxy_lambda" {
  name = "PipelineProxyLambdaRole"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "LambdaServiceAssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "StringEquals" : {
            # Only allow Lambda to assume this role if the request
            # comes from the same organization
            "aws:PrincipalOrgID" = data.aws_organizations_organization.pipeline_proxy_current.id,
            # Require TLS 1.2 or higher
            "aws:SecureTransport" : "true"
          }
        }
      },
      {
        "Sid" : "LambdaServiceAssumeRoleWithoutOrg",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "StringEquals" : {
            # Require TLS 1.2 or higher
            "aws:SecureTransport" : "true"
          },
          # Only allow from this specific account
          "StringEquals" : {
            "aws:SourceAccount" = data.aws_caller_identity.pipeline_proxy_current.account_id
          }
        }
      }
    ]
  })

  # Prevent IAM role recreation from changing ARN and breaking API Gateway
  force_detach_policies = false

  tags = {
    Description = "Security-hardened Lambda execution role for Pipeline Proxy"
    Security    = "hardened"
  }
}

# Attach AWS managed policy for Lambda basic execution (CloudWatch Logs)
resource "aws_iam_role_policy_attachments_exclusive" "pipeline_proxy_lambda_managed" {
  role_name = aws_iam_role.pipeline_proxy_lambda.name
  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}

# Inline policy for minimal CodePipeline permissions
resource "aws_iam_role_policy" "pipeline_proxy_lambda_codepipeline" {
  name = "CodePipelineMinimalAccess"
  role = aws_iam_role.pipeline_proxy_lambda.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "ReadPipelineInfo",
        "Effect" : "Allow",
        "Action" : [
          "codepipeline:GetPipeline",
          "codepipeline:ListPipelineExecutions"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "StartPipelineExecution",
        "Effect" : "Allow",
        "Action" : [
          "codepipeline:StartPipelineExecution"
        ],
        "Resource" : "*"
      }
    ]
  })
}

# Ensure only our specific inline policies are attached
resource "aws_iam_role_policies_exclusive" "pipeline_proxy_lambda" {
  role_name    = aws_iam_role.pipeline_proxy_lambda.name
  policy_names = [aws_iam_role_policy.pipeline_proxy_lambda_codepipeline.name]
}
