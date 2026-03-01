resource "aws_ssoadmin_permission_set" "SlackUser" {
  name         = "SlackUser"
  description  = "Custom role to map Slack to User Role"
  instance_arn = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
}
resource "aws_ssoadmin_managed_policy_attachments_exclusive" "SlackUser" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.SlackUser.arn

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess",
  ]
}

resource "aws_ssoadmin_permission_set_inline_policy" "AllowSlackUserRole" {
  for_each = {
    "SlackUser" : {
      permission_set_arn = aws_ssoadmin_permission_set.SlackUser.arn
    },
  }

  instance_arn       = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  permission_set_arn = each.value.permission_set_arn
  inline_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowSlackUserRole",
        "Effect" : "Allow",
        "Action" : [
          "chatbot:Describe*",
          "chatbot:GetAccountPreferences",
          "chatbot:GetSlackOauthParameters",
          "chatbot:List*",
          "chatbot:RedeemSlackOauthCode",
        ],
        "Resource" : [
          "*"
        ]
      },
    ]
  })
}

resource "aws_identitystore_group" "SlackUsers" {
  display_name      = "SlackUsers"
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso.identity_store_ids)[0]
}

resource "aws_ssoadmin_account_assignment" "SlackUser" {
  for_each = merge({ "deployment_builds" : aws_organizations_account.deployment_account["deployment_builds"] })

  instance_arn       = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.SlackUser.arn

  principal_id   = aws_identitystore_group.SlackUsers.group_id
  principal_type = "GROUP"

  target_id   = each.value.id
  target_type = "AWS_ACCOUNT"
}
