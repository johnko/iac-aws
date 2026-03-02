resource "aws_iam_role" "crossaccount_terraform_apply" {
  name = "CrossAccountPipelineRole-TerraformApply"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${var.aws_account_id_deployment_builds}:root"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachments_exclusive" "crossaccount_terraform_apply" {
  role_name = aws_iam_role.crossaccount_terraform_apply.name
  policy_arns = [
    "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess" # ViewOnly to avoid reading sensitive data like Secrets or S3
  ]
}

locals {
  crossaccount_inline_policies_apply = {
    # This role starts with ViewOnly to avoid reading sensitive data like Secrets or S3
    # Here, be very selective what permissions are granted
    CrossAccountInlinePolicy1 = {
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Action" : [
              "iam:GetRole"
            ],
            "Resource" : "*",
            "Effect" : "Allow"
          },
        ]
      })
    }
  }
}

resource "aws_iam_role_policy" "crossaccount_terraform_apply" {
  for_each = local.crossaccount_inline_policies_apply

  name   = each.key
  role   = aws_iam_role.crossaccount_terraform_apply.id
  policy = each.value.policy
}

resource "aws_iam_role_policies_exclusive" "crossaccount_terraform_apply" {
  role_name    = aws_iam_role.crossaccount_terraform_apply.name
  policy_names = keys(aws_iam_role_policy.crossaccount_terraform_apply)
}
