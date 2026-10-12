#!/usr/bin/env bash
set -euxo pipefail

# Try to disable the current pipeline's stage transition to prevent the TerraformPlan stage to be superseded by the next queued execution
# Will need to re-enable stage transition via the buildspec_post_build.sh
set +e

STAGE_NAME=Plan
if [[ $CODEPIPELINE_NAME =~ ^CDK-.* ]]; then
  STAGE_NAME=Diff
fi

aws codepipeline disable-stage-transition \
  --pipeline-name "$CODEPIPELINE_NAME" \
  --stage-name "$STAGE_NAME" \
  --transition-type Inbound \
  --reason "Automatically disabled stage transition - TerraformPlan or CDKDiff was running and needs review for ApproveOrReject before TerraformApply or CDKDeploy"
