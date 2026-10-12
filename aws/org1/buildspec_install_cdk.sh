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

npm install --global cdk@2.1144.0

cdk --version

set +x
