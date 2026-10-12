#!/usr/bin/env bash
set -euxo pipefail

if [[ $CI != true ]]; then
  bash ../../buildspec_cache_dependencies.sh
fi
