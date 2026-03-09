locals {
  ssm_parameters = {
    aws_account_id_deployment_builds       = { value = var.aws_account_id_deployment_builds }
    aws_account_id_management              = { value = var.aws_account_id_management }
    aws_account_id_sandbox_bedrock         = { value = var.aws_account_id_sandbox_bedrock }
    aws_account_id_security_aggregator     = { value = var.aws_account_id_security_aggregator }
    aws_account_id_security_cloudtrail     = { value = var.aws_account_id_security_cloudtrail }
    aws_AISERVICES_OPT_OUT_POLICY          = { value = var.aws_AISERVICES_OPT_OUT_POLICY }
    aws_CHATBOT_POLICY                     = { value = var.aws_CHATBOT_POLICY }
    aws_controltower_landingzone_id        = { value = var.aws_controltower_landingzone_id }
    aws_EC2_IMDSv2_POLICY                  = { value = var.aws_EC2_IMDSv2_POLICY }
    aws_EC2_NoIngressVPC_POLICY            = { value = var.aws_EC2_NoIngressVPC_POLICY }
    aws_EC2_NoMarketplaceAMI_POLICY        = { value = var.aws_EC2_NoMarketplaceAMI_POLICY }
    aws_EC2_NoPublicSharingAMI_POLICY      = { value = var.aws_EC2_NoPublicSharingAMI_POLICY }
    aws_EC2_NoPublicSharingSnapshot_POLICY = { value = var.aws_EC2_NoPublicSharingSnapshot_POLICY }
    aws_EC2_NoSerial_POLICY                = { value = var.aws_EC2_NoSerial_POLICY }
    aws_email_deployment_builds            = { value = var.aws_email_deployment_builds }
    aws_email_sandbox_bedrock              = { value = var.aws_email_sandbox_bedrock }
    aws_email_security_aggregator          = { value = var.aws_email_security_aggregator }
    aws_email_security_cloudtrail          = { value = var.aws_email_security_cloudtrail }
    aws_org_id                             = { value = var.aws_org_id }
    aws_org_root_id                        = { value = var.aws_org_root_id }
    aws_ou_id_deployment                   = { value = var.aws_ou_id_deployment }
    aws_ou_id_quarantine                   = { value = var.aws_ou_id_quarantine }
    aws_ou_id_sandbox                      = { value = var.aws_ou_id_sandbox }
    aws_ou_id_security                     = { value = var.aws_ou_id_security }
    aws_S3_POLICY                          = { value = var.aws_S3_POLICY }
    aws_SCP_OnlyOrgIdentityCenter_POLICY   = { value = var.aws_SCP_OnlyOrgIdentityCenter_POLICY }
    aws_SCP_QuarantineDenyAll_POLICY       = { value = var.aws_SCP_QuarantineDenyAll_POLICY }
    aws_TAG_iacdeployerEnumValues_POLICY   = { value = var.aws_TAG_iacdeployerEnumValues_POLICY }
    codeconnection_deployment_builds       = { value = var.codeconnection_deployment_builds }
    slack_team_name                        = { value = var.slack_team_name }
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
