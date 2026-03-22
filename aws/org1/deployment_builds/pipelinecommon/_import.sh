#!/usr/bin/env bash
set -euxo pipefail

TERRAFORM_FILENAME="terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
TERRAFORM_SHAFILE="terraform_${TERRAFORM_VERSION}_SHA256SUMS"

if [[ ! -e $TERRAFORM_SHAFILE ]] && [[ $CI != true ]]; then
  curl -LO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TERRAFORM_SHAFILE}"
  for i in cacentral1 useast2; do
    # shellcheck disable=SC2154
    if aws s3api get-bucket-location --bucket "codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i" --no-cli-pager; then
      maybe_filename=$(aws s3api list-objects-v2 --bucket "codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i" --prefix "$TERRAFORM_SHAFILE" --output text --no-cli-pager --query 'Contents[].Key')
      if [[ $maybe_filename != "$TERRAFORM_SHAFILE" ]]; then
        aws s3 cp "$TERRAFORM_SHAFILE" "s3://codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i/"
      fi
    fi
  done
fi

if [[ ! -e $TERRAFORM_FILENAME ]] && [[ $CI != true ]]; then
  curl -LO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TERRAFORM_FILENAME}"
  for i in cacentral1 useast2; do
    if aws s3api get-bucket-location --bucket "codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i" --no-cli-pager; then
      maybe_filename=$(aws s3api list-objects-v2 --bucket "codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i" --prefix "$TERRAFORM_FILENAME" --output text --no-cli-pager --query 'Contents[].Key')
      if [[ $maybe_filename != "$TERRAFORM_FILENAME" ]]; then
        aws s3 cp "$TERRAFORM_FILENAME" "s3://codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i/"
      fi
    fi
  done
fi
