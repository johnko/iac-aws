variable "slack_team_name" {
  type        = string
  description = "ARN of the CodeConnection, eg. arn:aws:codeconnections:us-west-1:0123456789:connection/79d4d357-a2ee-41e4-b350-2fe39ae59448"
}

import {
  to = aws_chatbot_slack_channel_configuration.channel["test-awschatbot"]
  id = "arn:aws:chatbot::${data.aws_caller_identity.current.account_id}:chat-configuration/slack-channel/test-awschatbot"
}

data "aws_chatbot_slack_workspace" "slack" {
  slack_team_name = var.slack_team_name
}

data "aws_iam_role" "channel" {
  for_each = local.slack_channels_enabled

  name = "AWSChatbotRole-${each.key}"
}

locals {
  slack_channels_enabled = {
    "test-awschatbot" = {
      slack_channel_id = "C04C86VPV26"
      slack_team_id    = data.aws_chatbot_slack_workspace.slack.slack_team_id
    }
  }
}

resource "aws_chatbot_slack_channel_configuration" "channel" {
  for_each = local.slack_channels_enabled

  configuration_name = each.key
  slack_channel_id   = each.value.slack_channel_id
  slack_team_id      = each.value.slack_team_id

  logging_level = "NONE"

  user_authorization_required = true # true=user specific permissions, false=shared channel permissions

  iam_role_arn = data.aws_iam_role.channel[each.key].arn
  guardrail_policy_arns = [
    "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
  ]

  tags = {
    Name = each.key
  }
}
