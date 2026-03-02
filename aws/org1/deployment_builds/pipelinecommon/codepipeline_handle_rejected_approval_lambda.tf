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
