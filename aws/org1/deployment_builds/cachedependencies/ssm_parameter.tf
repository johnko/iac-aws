
variable "cached_terraform_version" {
  type        = string
  description = "Terraform version that is cached"
}

locals {
  ssm_parameters = {
    cached_terraform_version = { value = var.cached_terraform_version }
  }
}

resource "aws_ssm_parameter" "param" {
  for_each = local.ssm_parameters

  name  = "TF_VAR_${each.key}"
  value = each.value.value
  type  = "String"
}

resource "aws_ssm_parameter" "secondary" {
  for_each = local.ssm_parameters

  region = local.codepipeline_secondary_region

  name  = "TF_VAR_${each.key}"
  value = each.value.value
  type  = "String"
}
