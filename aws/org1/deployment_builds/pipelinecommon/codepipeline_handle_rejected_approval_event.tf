resource "aws_sns_topic" "terraform_codepipeline_rejected" {
  for_each = {
    for k in [local.primary_region, local.secondary_region] : k => {
      "region" : k
    }
  }

  region = each.value.region

  name = "terraform-codepipeline-rejected"
}

resource "aws_sns_topic_policy" "terraform_codepipeline_rejected" {
  for_each = {
    for k in [local.primary_region, local.secondary_region] : k => {
      "region" : k
    }
  }

  region = each.value.region

  arn = aws_sns_topic.terraform_codepipeline_rejected[each.key].arn
  policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Sid" : "__default_statement_ID",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : [
          "SNS:GetTopicAttributes",
          "SNS:SetTopicAttributes",
          "SNS:AddPermission",
          "SNS:RemovePermission",
          "SNS:DeleteTopic",
          "SNS:Subscribe",
          "SNS:ListSubscriptionsByTopic",
          "SNS:Publish",
          "SNS:Receive"
        ],
        "Resource" : aws_sns_topic.terraform_codepipeline_rejected[each.key].arn,
        "Condition" : {
          "StringEquals" : {
            "AWS:SourceOwner" : "${data.aws_caller_identity.current.account_id}"
          }
        }
      },
      {
        "Sid" : "TrustCWEToPublishEventsToMyTopic",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "events.amazonaws.com"
        },
        "Action" : "sns:Publish",
        "Resource" : [
          aws_sns_topic.terraform_codepipeline_rejected[each.key].arn
        ]
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "terraform_codepipeline_rejected" {
  for_each = {
    for k in [local.primary_region, local.secondary_region] : k => {
      "region" : k
    }
  }

  region = each.value.region

  name        = "capture-terraform-codepipeline-rejected"
  description = "Capture each approval action that is rejected"
  # See https://docs.aws.amazon.com/codepipeline/latest/userguide/detect-state-changes-cloudwatch-events.html#create-cloudwatch-notifications
  event_pattern = jsonencode({
    "source" : [
      "aws.codepipeline"
    ],
    "detail-type" : [
      "CodePipeline Action Execution State Change"
    ],
    "detail" : {
      "state" : [
        "FAILED"
      ],
      "type" : {
        "category" : ["Approval"]
      },
      "pipeline" : [{
        "prefix" : "TF-"
      }]
    }
  })
}

resource "aws_cloudwatch_event_target" "terraform_codepipeline_rejected" {
  for_each = {
    for k in [local.primary_region, local.secondary_region] : k => {
      "region" : k
    }
  }

  region = each.value.region

  rule      = aws_cloudwatch_event_rule.terraform_codepipeline_rejected[each.key].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.terraform_codepipeline_rejected[each.key].arn
}
