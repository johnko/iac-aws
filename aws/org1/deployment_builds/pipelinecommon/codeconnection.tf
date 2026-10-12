import {
  to = aws_codeconnections_connection.johnko
  id = var.codeconnection_deployment_builds
}

resource "aws_codeconnections_connection" "johnko" {
  name          = "github-johnko"
  provider_type = "GitHub"
}
