#!/usr/bin/env bash
set -euo pipefail

find aws -type f -name _import.sh | sort | xargs dirname | awk "{print \"bash .github/tf.sh \"\$1\" $1\"}"
