# Lambda Function for Secure Pipeline Execution Proxy
# Agents invoke this Lambda directly to trigger pipelines WITHOUT source revision override

# Data source for current AWS account
data "aws_caller_identity" "startpipeline_lambda" {}

locals {
  lambda_name    = "startpipeline"
  lambda_handler = "lambda_function.handler"
  lambda_runtime = "python3.13"
  lambda_timeout = 30
  lambda_memory  = 256

  # Create a hash of the Python code for deployment tracking
  lambda_code_hash = filesha256("${path.module}/lambda_startpipeline/lambda_function.py")
}

# Archive the Lambda function code
data "archive_file" "startpipeline_lambda" {
  type        = "zip"
  output_path = "${path.module}/.terraform/lambda_startpipeline.zip"

  source {
    content  = file("${path.module}/lambda_startpipeline/lambda_function.py")
    filename = "lambda_function.py"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "startpipeline_lambda" {
  name = "StartPipelineLambdaRole"

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
            "aws:SourceAccount" = data.aws_caller_identity.startpipeline_lambda.account_id
          }
        }
      }
    ]
  })

  force_detach_policies = false

  tags = {
    Description = "Lambda execution role for Start Pipeline"
  }
}

# Attach AWS managed policy for Lambda basic execution (CloudWatch Logs)
resource "aws_iam_role_policy_attachments_exclusive" "startpipeline_lambda_managed" {
  role_name = aws_iam_role.startpipeline_lambda.name
  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}

# Inline policy for minimal CodePipeline permissions
resource "aws_iam_role_policy" "startpipeline_lambda_codepipeline" {
  name = "CodePipelineMinimalAccess"
  role = aws_iam_role.startpipeline_lambda.id

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
resource "aws_iam_role_policies_exclusive" "startpipeline_lambda" {
  role_name    = aws_iam_role.startpipeline_lambda.name
  policy_names = [aws_iam_role_policy.startpipeline_lambda_codepipeline.name]
}

# Lambda function resource
resource "aws_lambda_function" "startpipeline" {
  function_name = local.lambda_name
  description   = "Secure proxy for CodePipeline executions - prevents source revision overrides"

  filename         = data.archive_file.startpipeline_lambda.output_path
  source_code_hash = data.archive_file.startpipeline_lambda.output_base64sha256

  role        = aws_iam_role.startpipeline_lambda.arn
  handler     = local.lambda_handler
  runtime     = local.lambda_runtime
  timeout     = local.lambda_timeout
  memory_size = local.lambda_memory

  # X-Ray tracing disabled to save cost

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }

  tags = {
    Name        = local.lambda_name
    Description = "Pipeline Execution Proxy"
  }
}

# CloudWatch Log Group for Lambda (with retention)
resource "aws_cloudwatch_log_group" "startpipeline_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.startpipeline.function_name}"
  retention_in_days = 30

  tags = {
    Name = "${local.lambda_name}-logs"
  }
}

# Allow CrossAccountAgentRole to invoke the Lambda function directly
resource "aws_lambda_permission" "startpipeline_agent_invoke" {
  statement_id  = "AllowCrossAccountAgentInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.startpipeline.function_name
  principal     = "arn:aws:iam::${var.aws_account_id_playground_rswea}:role/CrossAccountAgentRole"
}
