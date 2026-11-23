# Lambda Function for Pipeline Proxy

locals {
  lambda_name    = "start-pipeline"
  lambda_handler = "lambda_function.handler"
  lambda_runtime = "python3.13"
  lambda_timeout = 30
  lambda_memory  = 256

  # Create a hash of the Python code for deployment tracking
  lambda_code_hash = filesha256("${path.module}/lambda_function.py")
}

# Archive the Lambda function code
data "archive_file" "pipeline_proxy_lambda" {
  type        = "zip"
  output_path = "${path.module}/.terraform/lambda_pipeline_proxy.zip"

  source {
    content  = file("${path.module}/lambda_function.py")
    filename = "lambda_function.py"
  }
}

# Lambda function resource
resource "aws_lambda_function" "pipeline_proxy" {
  function_name = local.lambda_name
  description   = "Secure proxy for CodePipeline executions - prevents source revision overrides"

  filename         = data.archive_file.pipeline_proxy_lambda.output_path
  source_code_hash = data.archive_file.pipeline_proxy_lambda.output_base64sha256

  role    = aws_iam_role.pipeline_proxy_lambda.arn
  handler = local.lambda_handler
  runtime = local.lambda_runtime
  timeout = local.lambda_timeout
  memory_size = local.lambda_memory

  # Enable X-Ray tracing for observability
  tracing_config {
    mode = "Active"
  }

  # Environment variables for configuration
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
resource "aws_cloudwatch_log_group" "pipeline_proxy" {
  name              = "/aws/lambda/${aws_lambda_function.pipeline_proxy.function_name}"
  retention_in_days = 30

  tags = {
    Name = "${local.lambda_name}-logs"
  }
}

# Allow CrossAccountAgentRole to invoke the Lambda function directly
# This eliminates the need for API Gateway
resource "aws_lambda_permission" "crossaccount_agent_invoke" {
  statement_id  = "AllowCrossAccountAgentInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pipeline_proxy.function_name
  principal     = "arn:aws:iam::${var.aws_account_id_playground_rswea}:role/CrossAccountAgentRole"
}
