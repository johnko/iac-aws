variable "slack_team_name" {
  type        = string
  description = "ARN of the CodeConnection, eg. arn:aws:codeconnections:us-west-1:0123456789:connection/79d4d357-a2ee-41e4-b350-2fe39ae59448"
}

import {
  to = aws_chatbot_slack_channel_configuration.channel["test-awschatbot"]
  id = "arn:aws:chatbot::${data.aws_caller_identity.current.account_id}:chat-configuration/slack-channel/test-awschatbot"
}

import {
  to = aws_iam_role.channel["test-awschatbot"]
  id = "AWSChatbotRole-test-awschatbot"
}

data "aws_chatbot_slack_workspace" "slack" {
  slack_team_name = var.slack_team_name
}

locals {
  slack_channels_enabled = {
    "test-awschatbot" = {
      slack_channel_id = "C04C86VPV26"
      slack_team_id    = data.aws_chatbot_slack_workspace.slack.slack_team_id
    }
  }
}

resource "aws_iam_role" "channel" {
  for_each = local.slack_channels_enabled

  name = "AWSChatbotRole-${each.key}"
  path = "/service-role/"

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

resource "aws_iam_role_policy_attachments_exclusive" "channel_attached" {
  for_each = local.slack_channels_enabled

  role_name   = aws_iam_role.channel[each.key].name
  policy_arns = [] # empty to prevent default channel role
}

resource "aws_iam_role_policies_exclusive" "channel_inline" {
  for_each = local.slack_channels_enabled

  role_name    = aws_iam_role.channel[each.key].name
  policy_names = [] # empty to prevent default channel role
}


resource "aws_chatbot_slack_channel_configuration" "channel" {
  for_each = local.slack_channels_enabled

  configuration_name = each.key
  slack_channel_id   = each.value.slack_channel_id
  slack_team_id      = each.value.slack_team_id

  logging_level = "NONE"

  user_authorization_required = true # true=user specific permissions, false=shared channel permissions

  iam_role_arn = aws_iam_role.channel[each.key].arn
  guardrail_policy_arns = [
    "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
  ]

  tags = {
    Name = each.key
  }
}
