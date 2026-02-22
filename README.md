# iac-aws

```shell
# load secrets
source .envrc

# format terraform workspace files
bash .github/tf.sh aws/org1/management fmt

bash .github/tf.sh aws/org1/management validate

bash .github/tf.sh aws/org1/management plan

bash .github/tf.sh aws/org1/management apply
```

## Reminders

1. Go to https://console.aws.amazon.com/controltower/home/accountfactory and empty "Regions for VPC creation"
2. Go to https://console.aws.amazon.com/controltower/home/organization and "Register organizational unit" for each OU
