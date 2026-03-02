#!/usr/bin/env bash
set -euxo pipefail

# Try to disable the current pipeline's stage transition to prevent the TerraformPlan stage to be superseded by the next queued execution
# Will need to disable via the buildspec_post_build.sh
set +e
aws codepipeline disable-stage-transition \
  --pipeline-name "$CODEPIPELINE_NAME" \
  --stage-name Plan \
  --transition-type Inbound \
  --reason "Automatic - Plan is running"
