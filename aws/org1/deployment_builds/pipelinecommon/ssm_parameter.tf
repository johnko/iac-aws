locals {
  ssm_parameters = {
    codeconnection_deployment_builds = {
      value = var.codeconnection_deployment_builds
    }
    aws_account_id_management = {
      value = var.aws_account_id_management
    }
    aws_account_id_security_aggregator = {
      value = var.aws_account_id_security_aggregator
    }
    aws_account_id_security_cloudtrail = {
      value = var.aws_account_id_security_cloudtrail
    }
    aws_account_id_sandbox_bedrock = {
      value = var.aws_account_id_sandbox_bedrock
    }
    aws_account_id_deployment_builds = {
      value = var.aws_account_id_deployment_builds
    }
  }
}

resource "aws_ssm_parameter" "param" {
  for_each = local.ssm_parameters

  name  = "TF_VAR_${each.key}"
  value = each.value.value
  type  = "String"
}
