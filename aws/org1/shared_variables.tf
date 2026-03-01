variable "aws_account_id" {
  type        = string
  description = "THIS AWS Account ID, eg. 111111111111"
}

variable "aws_account_id_management" {
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

variable "aws_account_id_sandbox_bedrock" {
  type        = string
  description = "AWS Account ID, eg. 111111111111"
}

variable "aws_account_id_deployment_builds" {
  type        = string
  description = "AWS Account ID, eg. 111111111111"
}

variable "slack_team_name" {
  type        = string
  description = "ARN of the CodeConnection, eg. arn:aws:codeconnections:us-west-1:0123456789:connection/79d4d357-a2ee-41e4-b350-2fe39ae59448"
}
