#!/usr/bin/env bash
set -euxo pipefail

bash ../../buildspec_cache_dependencies.sh

bash ../../buildspec_install.sh

cd ../../../../
bash .github/tf.sh $WORKSPACE_PATH plan || true
