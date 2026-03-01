locals {
  default_inline_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*"
        ],
        "Effect" : "Allow",
        "Resource" : "*",
        "Sid" : "AWSChatbotNotificationsOnlyPolicy"
      }
    ]
  })
}

resource "aws_iam_role" "chatbot_user" {
  for_each = local.slack_user_roles

  name = "UserChatbotRole-${each.key}"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "chatbot.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

}

resource "aws_iam_role_policy_attachments_exclusive" "chatbot_user_attached" {
  for_each = local.slack_user_roles

  role_name = aws_iam_role.chatbot_user[each.key].name
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonQDeveloperAccess"
  ]
}

resource "aws_iam_role_policy" "inline_policy1" {
  for_each = local.slack_user_roles

  name = "inline_policy1"
  role = aws_iam_role.chatbot_user[each.key].id

  policy = try(length(each.value.inline_policy1) > 0, false) ? each.value.inline_policy1 : local.default_inline_policy
}

resource "aws_iam_role_policies_exclusive" "chatbot_user_inline" {
  for_each = local.slack_user_roles

  role_name    = aws_iam_role.chatbot_user[each.key].name
  policy_names = [resource.aws_iam_role_policy.inline_policy1[each.key].name]
}
