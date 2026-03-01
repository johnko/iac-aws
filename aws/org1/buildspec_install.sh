#!/usr/bin/env bash
set -euxo pipefail

if [[ -e .envrc ]]; then
  set +x
  # hide secret env values from output
  # shellcheck disable=SC1091
  source .envrc
fi

# verbose to see install steps
set -x

TERRAFORM_FILENAME="terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
i=$(echo "$AWS_REGION" | tr -d '-')
if aws s3api get-bucket-location --bucket "codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i" --no-cli-pager; then
  maybe_filename=$(aws s3api list-objects-v2 --bucket "codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i" --prefix "$TERRAFORM_FILENAME" --output text --no-cli-pager --query 'Contents[].Key')
  if [[ $maybe_filename == "$TERRAFORM_FILENAME" ]]; then
    aws s3 cp "s3://codepipeline-${TF_VAR_aws_account_id_deployment_builds}-$i/$TERRAFORM_FILENAME" ./ --quiet
    unzip "$TERRAFORM_FILENAME"
    mkdir -p ~/bin
    mv terraform ~/bin/
    export PATH=$PATH:~/bin
  fi
fi

if ! echo "$EXECUTOR_TYPE" | grep LAMBDA; then
  if ! terraform version &>/dev/null; then
    export release=AmazonLinux
    dnf install -y dnf-plugins-core
    dnf config-manager --add-repo https://rpm.releases.hashicorp.com/$release/hashicorp.repo
    dnf install -y terraform
  fi
fi

terraform version

set +x
