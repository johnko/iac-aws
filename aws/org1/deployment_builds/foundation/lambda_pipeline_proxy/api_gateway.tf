# API Gateway for Pipeline Proxy Lambda

locals {
  api_name        = "pipeline-proxy-api"
  api_stage_name  = "v1"
  api_description = "API for secure CodePipeline execution proxy"
}

# REST API Gateway
resource "aws_api_gateway_rest_api" "pipeline_proxy" {
  name        = local.api_name
  description = local.api_description

  # Request validation
  request_validator {
    name                        = "pipeline-proxy-validator"
    validate_request_body       = true
    validate_request_parameters = true
  }

  # API Gateway policy - only allow requests from within the VPC where agents run
  endpoint_configuration {
    types = ["REGIONAL"]
  }

  # Throttling settings
  api_key_source = "HEADER"
}

# Resource: /execute
resource "aws_api_gateway_resource" "execute" {
  rest_api_id = aws_api_gateway_rest_api.pipeline_proxy.id
  parent_id   = aws_api_gateway_rest_api.pipeline_proxy.root_resource_id
  path_part   = "execute"
}

# Method: POST /execute
resource "aws_api_gateway_method" "execute_post" {
  rest_api_id = aws_api_gateway_rest_api.pipeline_proxy.id
  resource_id = aws_api_gateway_resource.execute.id
  http_method = "POST"

  authorization = "AWS_IAM"
  # Require API key for throttling control
  api_key_required = false

  request_parameters = {
    "method.request.header.Content-Type" = true
  }
}

# Integration: Lambda proxy
resource "aws_api_gateway_integration" "execute_lambda" {
  rest_api_id = aws_api_gateway_rest_api.pipeline_proxy.id
  resource_id = aws_api_gateway_resource.execute.id
  http_method = aws_api_gateway_method.execute_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.pipeline_proxy.invoke_arn

  # Lambda integration timeout (should be less than Lambda timeout)
  timeout_milliseconds = 29000
}

# Method response
resource "aws_api_gateway_method_response" "execute_200" {
  rest_api_id = aws_api_gateway_rest_api.pipeline_proxy.id
  resource_id = aws_api_gateway_resource.execute.id
  http_method = aws_api_gateway_method.execute_post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
    "method.response.header.X-Request-ID" = true
  }
}

# Integration response
resource "aws_api_gateway_integration_response" "execute_200" {
  rest_api_id = aws_api_gateway_rest_api.pipeline_proxy.id
  resource_id = aws_api_gateway_resource.execute.id
  http_method = aws_api_gateway_method.execute_post.http_method
  status_code = aws_api_gateway_method_response.execute_200.status_code

  depends_on = [aws_api_gateway_integration.execute_lambda]
}

# Method response for 400
resource "aws_api_gateway_method_response" "execute_400" {
  rest_api_id = aws_api_gateway_rest_api.pipeline_proxy.id
  resource_id = aws_api_gateway_resource.execute.id
  http_method = aws_api_gateway_method.execute_post.http_method
  status_code = "400"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

# Method response for 403
resource "aws_api_gateway_method_response" "execute_403" {
  rest_api_id = aws_api_gateway_rest_api.pipeline_proxy.id
  resource_id = aws_api_gateway_resource.execute.id
  http_method = aws_api_gateway_method.execute_post.http_method
  status_code = "403"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

# Method response for 404
resource "aws_api_gateway_method_response" "execute_404" {
  rest_api_id = aws_api_gateway_rest_api.pipeline_proxy.id
  resource_id = aws_api_gateway_resource.execute.id
  http_method = aws_api_gateway_method.execute_post.http_method
  status_code = "404"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

# Method response for 429
resource "aws_api_gateway_method_response" "execute_429" {
  rest_api_id = aws_api_gateway_rest_api.pipeline_proxy.id
  resource_id = aws_api_gateway_resource.execute.id
  http_method = aws_api_gateway_method.execute_post.http_method
  status_code = "429"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

# Method response for 500
resource "aws_api_gateway_method_response" "execute_500" {
  rest_api_id = aws_api_gateway_rest_api.pipeline_proxy.id
  resource_id = aws_api_gateway_resource.execute.id
  http_method = aws_api_gateway_method.execute_post.http_method
  status_code = "500"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

# Deployment
resource "aws_api_gateway_deployment" "pipeline_proxy" {
  rest_api_id = aws_api_gateway_rest_api.pipeline_proxy.id

  # Trigger redeployment when resources change
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.execute.id,
      aws_api_gateway_method.execute_post.id,
      aws_api_gateway_integration.execute_lambda.id,
      filesha256("${path.module}/lambda_function.py"),
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Stage
resource "aws_api_gateway_stage" "pipeline_proxy" {
  deployment_id = aws_api_gateway_deployment.pipeline_proxy.id
  rest_api_id   = aws_api_gateway_rest_api.pipeline_proxy.id
  stage_name    = local.api_stage_name

  # Logging and metrics
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      integrationLatency = "$context.integrationLatency"
    })
  }

  # Method settings for throttling
  dynamic "additional_settings" {
    for_each = []
    content {}
  }

  tags = {
    Name = "${local.api_name}-${local.api_stage_name}"
  }
}

# Method settings for throttling
resource "aws_api_gateway_method_settings" "pipeline_proxy" {
  rest_api_id = aws_api_gateway_rest_api.pipeline_proxy.id
  stage_name  = aws_api_gateway_stage.pipeline_proxy.stage_name
  method_path = "*/*"

  settings {
    throttling_rate_limit  = 10   # requests per second
    throttling_burst_limit = 20  # burst requests
    logging_level        = "INFO"
    data_trace_enabled   = true
    metrics_enabled      = true
  }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${local.api_name}"
  retention_in_days = 30

  tags = {
    Name = "${local.api_name}-logs"
  }
}

# IAM role for API Gateway CloudWatch logging
resource "aws_api_gateway_account" "pipeline_proxy" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "ApiGatewayCloudWatchRole"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "APIGatewayAssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "apigateway.amazonaws.com"
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "StringEquals" : {
            # Require TLS 1.2 or higher
            "aws:SecureTransport" : "true",
            # Only allow from this specific account
            "aws:SourceAccount" = data.aws_caller_identity.pipeline_proxy_current.account_id
          }
        }
      }
    ]
  })

  tags = {
    Description = "Security-hardened CloudWatch logging role for API Gateway"
    Security    = "hardened"
  }
}

resource "aws_iam_role_policy" "api_gateway_cloudwatch" {
  name = "CloudWatchLogsAccess"
  role = aws_iam_role.api_gateway_cloudwatch.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents"
        ],
        "Resource" : "*"
      }
    ]
  })
}

# Output the API Gateway endpoint URL
output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL for pipeline proxy"
  value       = "${aws_api_gateway_stage.pipeline_proxy.invoke_url}/execute"
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_api_gateway_rest_api.pipeline_proxy.id
}
