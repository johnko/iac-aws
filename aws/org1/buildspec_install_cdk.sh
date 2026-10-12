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

if [[ -e package-lock.json ]]; then
  if grep -q '"cdk"' package-lock.json; then
    npm ci
  else
    npm install cdk@2.1144.0
  fi
fi

cdk --version

set +x
