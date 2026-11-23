# IAM Role and Policy for Lambda Pipeline Proxy

resource "aws_iam_role" "pipeline_proxy_lambda" {
  name = "PipelineProxyLambdaRole"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
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
