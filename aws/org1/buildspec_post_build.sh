#!/usr/bin/env bash
set -euxo pipefail

# Try to enable the current pipeline's stage transition to allow the pipeline to resume after pausing for current execution
set +e
aws codepipeline enable-stage-transition \
  --pipeline-name "$CODEPIPELINE_NAME" \
  --stage-name Plan \
  --transition-type Inbound
