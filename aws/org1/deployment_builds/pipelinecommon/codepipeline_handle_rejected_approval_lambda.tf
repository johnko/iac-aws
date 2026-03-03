resource "aws_iam_role" "terraform_codepipeline_rejected" {
  name = "LambdaRole-TerraformCodePipelineRejected"
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

resource "aws_iam_role_policy_attachments_exclusive" "terraform_codepipeline_rejected" {
  role_name = aws_iam_role.terraform_codepipeline_rejected.name
  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}

resource "aws_iam_role_policy" "LambdaRoleStageTransitionPolicy" {
  name = "LambdaRoleStageTransitionPolicy"
  role = aws_iam_role.terraform_codepipeline_rejected.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        # Allow to enable the Plan stage transition especially when Approval was rejected
        "Action" : [
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

resource "aws_iam_role_policies_exclusive" "terraform_codepipeline_rejected" {
  role_name = aws_iam_role.terraform_codepipeline_rejected.name
  policy_names = [
    aws_iam_role_policy.LambdaRoleStageTransitionPolicy.name,
  ]
}

# Package the Lambda function code
data "archive_file" "terraform_codepipeline_rejected" {
  output_path = "${path.module}/lambda/terraform_codepipeline_rejected.zip"
  source_file = "${path.module}/lambda/terraform_codepipeline_rejected.py"
  type        = "zip"
}

resource "aws_lambda_function" "terraform_codepipeline_rejected" {
  for_each = {
    for k in [local.primary_region, local.secondary_region] : k => {
      "region" : k
    }
  }

  region = each.value.region

  code_sha256   = filesha256("${path.module}/lambda/terraform_codepipeline_rejected.py")
  filename      = data.archive_file.terraform_codepipeline_rejected.output_path
  function_name = "TerraformCodePipelineRejectedEnableStageTransition"
  handler       = "terraform_codepipeline_rejected.lambda_handler"
  role          = aws_iam_role.terraform_codepipeline_rejected.arn
  runtime       = "python3.13"
  timeout       = 60
}

resource "aws_lambda_function_event_invoke_config" "terraform_codepipeline_rejected" {
  for_each = {
    for k in [local.primary_region, local.secondary_region] : k => {
      "region" : k
    }
  }

  region = each.value.region

  function_name = "TerraformCodePipelineRejectedEnableStageTransition"

  maximum_event_age_in_seconds = 300
  maximum_retry_attempts       = 0
}

resource "aws_lambda_permission" "terraform_codepipeline_rejected" {
  for_each = {
    for k in [local.primary_region, local.secondary_region] : k => {
      "region" : k
    }
  }

  region = each.value.region

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_codepipeline_rejected[each.key].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.terraform_codepipeline_rejected[each.key].arn
  statement_id  = "AllowExecutionFromSNS"
}

resource "aws_sns_topic_subscription" "terraform_codepipeline_rejected" {
  for_each = {
    for k in [local.primary_region, local.secondary_region] : k => {
      "region" : k
    }
  }

  region = each.value.region

  endpoint  = aws_lambda_function.terraform_codepipeline_rejected[each.key].arn
  protocol  = "lambda"
  topic_arn = aws_sns_topic.terraform_codepipeline_rejected[each.key].arn
}
