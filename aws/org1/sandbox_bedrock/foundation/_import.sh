#!/usr/bin/env bash
set -euxo pipefail

terraform state show 'aws_s3_bucket.terraform_state' ||
  terraform state rm 'aws_s3_bucket.terraform_state'
