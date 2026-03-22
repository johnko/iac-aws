#!/usr/bin/env bash
set -euxo pipefail

for i in \
  'aws_s3_bucket.terraform_state' \
  'aws_s3_bucket.terraform_state_replica["ca-west-1"]' \
  'aws_s3_bucket.terraform_state_replica["us-east-2"]' \
  'aws_s3_bucket_ownership_controls.terraform_state' \
  'aws_s3_bucket_ownership_controls.terraform_state_replica["ca-west-1"]' \
  'aws_s3_bucket_ownership_controls.terraform_state_replica["us-east-2"]' \
  'aws_s3_bucket_public_access_block.terraform_state' \
  'aws_s3_bucket_public_access_block.terraform_state_replica["ca-west-1"]' \
  'aws_s3_bucket_public_access_block.terraform_state_replica["us-east-2"]' \
  'aws_s3_bucket_request_payment_configuration.terraform_state' \
  'aws_s3_bucket_request_payment_configuration.terraform_state_replica["ca-west-1"]' \
  'aws_s3_bucket_request_payment_configuration.terraform_state_replica["us-east-2"]' \
  'aws_s3_bucket_versioning.terraform_state' \
  'aws_s3_bucket_versioning.terraform_state_replica["ca-west-1"]' \
  'aws_s3_bucket_versioning.terraform_state_replica["us-east-2"]' \
  ; do
  terraform state show "$i" &&
    terraform state rm "$i" || true
done
