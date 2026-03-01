# iac-aws

## First time

- Enable AWS Billing
- Set a budget threshold and notifications
- Enable AWS Organizations
- Enable AWS Control Tower (see `aws/org1/management/foundation/controltower_landing_zone.tf`)
  - Automatic account enrollment: true
  - Regions, Region deny control: true (see `aws/org1/shared_locals.tf`)
  - AWS Config: true
  - AWS CloudTrail: true
  - AWS IAM Identity Center: true
  - AWS Backup: false
- Manually delete default VPCs

```shell
# load secrets
source .envrc

# format terraform workspace files
bash .github/tf.sh aws/org1/management/foundation fmt

bash .github/tf.sh aws/org1/management/foundation validate

bash .github/tf.sh aws/org1/management/foundation plan

bash .github/tf.sh aws/org1/management/foundation apply
```

## After AWS Control Tower is ready

1. Go to https://console.aws.amazon.com/controltower/home/accountfactory and empty "Regions for VPC creation".
2. Go to https://console.aws.amazon.com/controltower/home/organization and "Register organizational unit" for each OU.

## After AWS Identity Center is ready

1. Go to https://console.aws.amazon.com/singlesignon/home and "Settings" and use the mutli-region KMS Key

## Onboarding new accounts

1. Go to https://console.aws.amazon.com/controltower/home/accountfactory and click "Create Account".
2. Allow NetworkAdministrator permissionset and NetworkAdmins group on new accounts via `resource "aws_ssoadmin_account_assignment" "NetworkAdministrator" {` (see `aws/org1/management/foundation/identity_center_permission_set_NetworkAdmin.tf`) to manually delete default VPCs. Avoid automation unless you have strict guardrails to prevent accidentally deleting other VPCs.
3. Manually delete default VPCs
4. Use https://resource-explorer.console.aws.amazon.com/resource-explorer/home to find all resources across all regions.
