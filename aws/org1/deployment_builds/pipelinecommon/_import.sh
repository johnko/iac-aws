#!/usr/bin/env bash
set -euxo pipefail

# renovate: datasource=github-releases depName=hashicorp/terraform packageName=hashicorp/terraform
TERRAFORM_VERSION="1.14.6"

TERRAFORM_FILENAME="terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

if [[ ! -e "$TERRAFORM_FILENAME" ]]; then
  curl -LO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TERRAFORM_FILENAME}"
fi

for i in cacentral1 useast2; do
  if aws s3api get-bucket-location --bucket codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i --no-cli-pager ; then
    maybe_filename=$(aws s3api list-objects-v2 --bucket codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i --prefix "$TERRAFORM_FILENAME" --output text --no-cli-pager --query 'Contents[].Key')
    if [[ "$maybe_filename" != "$TERRAFORM_FILENAME" ]]; then
      aws s3 cp "$TERRAFORM_FILENAME" s3://codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i/
    fi
  fi
done
