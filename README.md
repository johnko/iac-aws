# iac-aws

## First time

- Enable AWS Billing
- Set a budget threshold and notifications
- Enable AWS Control Tower (see `aws/org1/management/controltower_landing_zone.tf`)
  - Automatic account enrollment: true
  - Regions, Region deny control: true (see `aws/org1/management/locals.tf`)
  - AWS Config: true
  - AWS CloudTrail: true
  - AWS IAM Identity Center: true
  - AWS Backup: false
- Manually delete default VPCs

```shell
# load secrets
source .envrc

# format terraform workspace files
bash .github/tf.sh aws/org1/management fmt

bash .github/tf.sh aws/org1/management validate

bash .github/tf.sh aws/org1/management plan

bash .github/tf.sh aws/org1/management apply
```

## After AWS Control Tower is ready

1. Go to https://console.aws.amazon.com/controltower/home/accountfactory and empty "Regions for VPC creation".
2. Go to https://console.aws.amazon.com/controltower/home/organization and "Register organizational unit" for each OU.
