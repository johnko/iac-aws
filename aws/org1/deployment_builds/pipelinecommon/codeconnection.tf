variable "codeconnection_deployment_prod_builds" {
  type        = string
  description = "ARN of the CodeConnection, eg. arn:aws:codeconnections:us-west-1:0123456789:connection/79d4d357-a2ee-41e4-b350-2fe39ae59448"
}

import {
  to = aws_codeconnections_connection.johnko
  id = var.codeconnection_deployment_prod_builds
}

resource "aws_codeconnections_connection" "johnko" {
  name          = "github-johnko"
  provider_type = "GitHub"
}
