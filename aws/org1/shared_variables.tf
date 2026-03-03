variable "aws_account_id" {
  type        = string
  description = "THIS AWS Account ID, eg. 111111111111"
}

variable "aws_account_id_deployment_builds" {
  type        = string
  description = "AWS Account ID, eg. 111111111111"
}
variable "aws_account_id_management" {
  type        = string
  description = "AWS Account ID, eg. 111111111111"
}
variable "aws_account_id_sandbox_bedrock" {
  type        = string
  description = "AWS Account ID, eg. 111111111111"
}
variable "aws_account_id_security_aggregator" {
  type        = string
  description = "AWS Account ID, eg. 111111111111"
}
variable "aws_account_id_security_cloudtrail" {
  type        = string
  description = "AWS Account ID, eg. 111111111111"
}
variable "aws_AISERVICES_OPT_OUT_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
variable "aws_CHATBOT_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
variable "aws_controltower_landingzone_id" {
  type        = string
  description = "AWS ControlTower LandingZone ID, eg. ABCD1234"
}
variable "aws_EC2_IMDSv2_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
variable "aws_EC2_NoIngressVPC_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
variable "aws_EC2_NoMarketplaceAMI_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
variable "aws_EC2_NoPublicSharingAMI_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
variable "aws_EC2_NoPublicSharingSnapshot_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
variable "aws_EC2_NoSerial_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
variable "aws_email_deployment_builds" {
  type        = string
  description = "Email address for the aws account"
}
variable "aws_email_sandbox_bedrock" {
  type        = string
  description = "Email address for the aws account"
}
variable "aws_email_security_aggregator" {
  type        = string
  description = "Email address for the aws account"
}
variable "aws_email_security_cloudtrail" {
  type        = string
  description = "Email address for the aws account"
}
variable "aws_org_id" {
  type        = string
  description = "Organization ID, eg. o-abc123"
}
variable "aws_ou_id_deployment" {
  type        = string
  description = "Organizational Unit ID, eg. ou-xyz789"
}
variable "aws_ou_id_quarantine" {
  type        = string
  description = "Organizational Unit ID, eg. ou-xyz789"
}
variable "aws_ou_id_sandbox" {
  type        = string
  description = "Organizational Unit ID, eg. ou-xyz789"
}
variable "aws_ou_id_security" {
  type        = string
  description = "Organizational Unit ID, eg. ou-xyz789"
}
variable "aws_S3_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
variable "aws_SCP_OnlyOrgIdentityCenter_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
variable "aws_SCP_QuarantineDenyAll_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
variable "aws_TAG_iacdeployerEnumValues_POLICY" {
  type        = string
  description = "Policy ID, eg. p-123"
}
variable "codeconnection_deployment_builds" {
  type        = string
  description = "ARN of the CodeConnection, eg. arn:aws:codeconnections:us-west-1:0123456789:connection/79d4d357-a2ee-41e4-b350-2fe39ae59448"
}
variable "slack_team_name" {
  type        = string
  description = "Slack Workspace Name, eg. My Workspace"
}
