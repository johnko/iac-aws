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

pushd "$WORKSPACE_PATH"

if [[ -e package-lock.json ]]; then
  if grep -q '"cdk"' package-lock.json; then
    npm ci
    npm pack
  fi
fi
if ! cdk --version &>/dev/null; then
  # npm install --global cdk@2.1144.0
  ls -l *.tgz
  npm install --global *.tgz
fi

cdk --version

set +x
