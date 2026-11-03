#!/usr/bin/env bash
set -euxo pipefail

# This script runs 'terraform init -upgrade' for all directories containing
# .terraform.lock.hcl files to update the lock files after Renovate upgrades
# Terraform provider versions.

# Find all directories with .terraform.lock.hcl files
for LOCKFILE in $(find . -name ".terraform.lock.hcl" -type f -not -path "*/.terraform/*" | sort -u); do
  DIR=$(dirname "$LOCKFILE")
  echo "Updating lock file in: $DIR"
  pushd "$DIR"

  # Skip directories with configuration errors (like prod_management/foundation)
  # which has import blocks requiring specific IDs
  if terraform init -upgrade 2>/dev/null; then
    echo "✓ Successfully upgraded $DIR"
  else
    echo "✗ Failed to upgrade $DIR (likely due to configuration issues)"
  fi

  # Clean up .terraform directory to keep the repo clean
  rm -rf .terraform

  popd
done

echo "Terraform lock file upgrade complete"
