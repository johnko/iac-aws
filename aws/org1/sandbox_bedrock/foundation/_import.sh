#!/usr/bin/env bash
set -euxo pipefail

terraform state show 'aws_s3_bucket.terraform_state' | grep cacentral1 ||
  terraform state rm 'aws_s3_bucket.terraform_state'

terraform state show 'aws_s3_bucket_ownership_controls.terraform_state' | grep cacentral1 ||
  terraform state rm 'aws_s3_bucket_ownership_controls.terraform_state'

terraform state show 'aws_s3_bucket_public_access_block.terraform_state' | grep cacentral1 ||
  terraform state rm 'aws_s3_bucket_public_access_block.terraform_state'

terraform state show 'aws_s3_bucket_replication_configuration.terraform_state' | grep cacentral1 ||
  terraform state rm 'aws_s3_bucket_replication_configuration.terraform_state'

terraform state show 'aws_s3_bucket_request_payment_configuration.terraform_state' | grep cacentral1 ||
  terraform state rm 'aws_s3_bucket_request_payment_configuration.terraform_state'

terraform state show 'aws_s3_bucket_versioning.terraform_state' | grep cacentral1 ||
  terraform state rm 'aws_s3_bucket_versioning.terraform_state'
