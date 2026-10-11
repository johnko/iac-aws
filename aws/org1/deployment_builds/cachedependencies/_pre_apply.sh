#!/usr/bin/env bash
set -euxo pipefail

VERSION_NUMBER="${TERRAFORM_VERSION#v}"
TERRAFORM_FILENAME="terraform_${VERSION_NUMBER}_linux_amd64.zip"
TERRAFORM_SHAFILE="terraform_${VERSION_NUMBER}_SHA256SUMS"
i="$AWS_REGION"
if aws s3api get-bucket-location --bucket "codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i-an" --no-cli-pager; then
  maybe_filename=$(aws s3api list-objects-v2 --bucket "codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i-an" --prefix "$TERRAFORM_FILENAME" --output text --no-cli-pager --query 'Contents[].Key')
  maybe_shafile=$(aws s3api list-objects-v2 --bucket "codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i-an" --prefix "$TERRAFORM_SHAFILE" --output text --no-cli-pager --query 'Contents[].Key')
  if [[ $maybe_filename != "$TERRAFORM_FILENAME" ]] && [[ $maybe_shafile != "$TERRAFORM_SHAFILE" ]]; then

    if [[ ! -e $TERRAFORM_SHAFILE ]]; then
      curl -LO "https://releases.hashicorp.com/terraform/${VERSION_NUMBER}/${TERRAFORM_SHAFILE}"
      for i in ca-central-1 us-east-2; do
        # shellcheck disable=SC2154
        if aws s3api get-bucket-location --bucket "codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i-an" --no-cli-pager; then
          maybe_filename=$(aws s3api list-objects-v2 --bucket "codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i-an" --prefix "$TERRAFORM_SHAFILE" --output text --no-cli-pager --query 'Contents[].Key')
          if [[ $maybe_filename != "$TERRAFORM_SHAFILE" ]]; then
            aws s3 cp "$TERRAFORM_SHAFILE" "s3://codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i-an/"
          fi
        fi
      done
    fi

    if [[ ! -e $TERRAFORM_FILENAME ]]; then
      curl -LO "https://releases.hashicorp.com/terraform/${VERSION_NUMBER}/${TERRAFORM_FILENAME}"
      for i in ca-central-1 us-east-2; do
        if aws s3api get-bucket-location --bucket "codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i-an" --no-cli-pager; then
          maybe_filename=$(aws s3api list-objects-v2 --bucket "codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i-an" --prefix "$TERRAFORM_FILENAME" --output text --no-cli-pager --query 'Contents[].Key')
          if [[ $maybe_filename != "$TERRAFORM_FILENAME" ]]; then
            aws s3 cp "$TERRAFORM_FILENAME" "s3://codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i-an/"
          fi
        fi
      done
    fi

  fi
fi

bash ../../buildspec_install.sh

cd ../../../../
bash .github/tf.sh $WORKSPACE_PATH plan || true
