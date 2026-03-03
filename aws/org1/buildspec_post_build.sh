#!/usr/bin/env bash
set -euxo pipefail

# Try to enable the current pipeline's stage transition to allow the pipeline to resume after pausing for current execution
set +e
aws codepipeline enable-stage-transition \
  --pipeline-name "$CODEPIPELINE_NAME" \
  --stage-name Plan \
  --transition-type Inbound

post_plan_to_slack() {
  if [[ -e $TF_TMP_LOG ]] && [[ $TF_TMP_LOG == *plan* ]]; then
    set +ux
    curl -X POST -H 'Content-type: application/json; charset=utf-8' \
      --data '{"text":"Plan for pipeline '"$CODEPIPELINE_NAME"' in region '"$AWS_REGION"'\n```'"$($(cat "$TF_TMP_LOG" |
        awk '/^No changes|^Terraform used the selected providers/,/NON MATCHING PATTERN TO GET ALL OUTPUT TO THE END/' | head -c 500))"'...```"}' \
      $TF_VAR_PLAN_SLACK_WEBHOOK_URL
  fi
}

post_plan_to_slack
