variable "aws_CHATBOT_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
import {
  to = aws_organizations_policy.CHATBOT_POLICY
  id = var.aws_CHATBOT_POLICY
}

resource "aws_organizations_policy" "CHATBOT_POLICY" {

  name = "AllowSlack"
  type = "CHATBOT_POLICY"

  content = jsonencode({
    "chatbot" : {
      "platforms" : {
        "chime" : {
          "client" : {
            "@@assign" : "disabled"
          }
        },
        "slack" : {
          "client" : {
            "@@assign" : "enabled"
          },
          "default" : {
            "supported_role_settings" : {
              "@@assign" : [
                "channel_role",
                "user_role"
              ]
            }
          }
        },
        "microsoft_teams" : {
          "client" : {
            "@@assign" : "disabled"
          }
        }
      },
      "default" : {
        "client" : {
          "@@assign" : "disabled"
        }
      }
    }
  })

  tags = {
    "iacdeployer" = "awsconsole"
  }

}

import {
  to = aws_organizations_policy_attachment.CHATBOT_POLICY_root
  identity = {
    policy_id = var.aws_CHATBOT_POLICY
    target_id = aws_organizations_organization.org.roots[0].id
  }
}

resource "aws_organizations_policy_attachment" "CHATBOT_POLICY_root" {
  policy_id = aws_organizations_policy.CHATBOT_POLICY.id
  target_id = aws_organizations_organization.org.roots[0].id
}
