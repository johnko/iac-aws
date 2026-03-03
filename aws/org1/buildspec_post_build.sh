#!/usr/bin/env bash
set -euxo pipefail

set +eu
# don't enable on TF_PLAN_EXIT_CODE 2 because it will enable stage transition for current pipeline, which will cause plan to be overwritten by next queued execution
if [[ -n "$TF_PLAN_EXIT_CODE" ]] && [[ $TF_PLAN_EXIT_CODE != 2 ]]; then
  # TF_PLAN_EXIT_CODE
  # 0 = Succeeded with empty diff (no changes), need to stop pipeline from going to TerraformApply
  # 2 = Succeeded with non-empty diff (changes present), need to continues pipeline to ApproveOrReject and TerraformApply
  # 1 = Error
  # Try to enable the current pipeline's stage transition if error or No changes to allow the pipeline to resume after pausing for current execution
  aws codepipeline enable-stage-transition \
    --pipeline-name "$CODEPIPELINE_NAME" \
    --stage-name Plan \
    --transition-type Inbound
fi

post_plan_to_slack() {
  if [[ -e $TF_TMP_LOG ]] && [[ $TF_TMP_LOG == *plan* ]]; then
    set +ux
    if [[ $TF_PLAN_EXIT_CODE != 0 ]]; then
      TF_PLAN_TEXT=$(cat "$TF_TMP_LOG" | awk '/^Terraform used the selected providers/,/NON MATCHING PATTERN TO GET ALL OUTPUT TO THE END/' | tr "\n" '`' | sed 's,`,\\n,g' | head -c 500)
      echo "{\"text\":\"Plan for pipeline $CODEPIPELINE_NAME in region $AWS_REGION\n\`\`\`\n$TF_PLAN_TEXT ...\n\`\`\`\"}"
      curl \
        -X POST \
        -H 'Content-type: application/json; charset=utf-8' \
        --data "{\"text\":\"\`\`\`Plan for pipeline $CODEPIPELINE_NAME in region $AWS_REGION\n\n$TF_PLAN_TEXT ...\`\`\`\"}" \
        $TF_VAR_PLAN_SLACK_WEBHOOK_URL
    fi
  fi
}
post_plan_to_slack
