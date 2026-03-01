resource "aws_ssoadmin_permission_set" "SlackUser" {
  for_each = local.slack_user_roles

  name         = "SlackUser-${each.key}"
  description  = "Custom role to map Slack to User Role ${each.key}"
  instance_arn = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
}
resource "aws_ssoadmin_managed_policy_attachments_exclusive" "SlackUser" {
  for_each = local.slack_user_roles

  instance_arn       = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.SlackUser[each.key].arn

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess",
  ]
}

resource "aws_ssoadmin_permission_set_inline_policy" "AllowSlackUserRole" {
  for_each = local.slack_user_roles

  instance_arn       = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.SlackUser[each.key].arn
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
  for_each = local.slack_user_roles

  display_name      = "SlackUsers-${each.key}"
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso.identity_store_ids)[0]
}

resource "aws_ssoadmin_account_assignment" "SlackUser" {
  for_each = local.slack_user_roles

  instance_arn       = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.SlackUser[each.key].arn

  principal_id   = aws_identitystore_group.SlackUsers[each.key].group_id
  principal_type = "GROUP"

  target_id   = aws_organizations_account.deployment_account["deployment_builds"].id
  target_type = "AWS_ACCOUNT"
}
