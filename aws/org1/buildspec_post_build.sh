#!/usr/bin/env bash
set -euxo pipefail

set +eu
# don't enable on TF_PLAN_EXIT_CODE 2 because it will enable stage transition for current pipeline, which will cause plan to be overwritten by next queued execution
if [[ -n $TF_PLAN_EXIT_CODE ]] && [[ $TF_PLAN_EXIT_CODE != 2 ]]; then
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
      # use sed to strip escape sequences like color
      TF_PLAN_TEXT=$(cat "$TF_TMP_LOG" \
        | sed 's/\x1b\[[0-9;]*m//g' \
        | awk '/^Terraform used the selected providers|^Plan:/,/^Terraform will perform the following actions|^────────────────────────────────────────────/' \
        | head -c 500)
      SLACK_PAYLOAD=$(jq -n \
        --arg pipeline "$CODEPIPELINE_NAME" \
        --arg region "$AWS_REGION" \
        --arg commitid "$CODEBUILD_RESOLVED_SOURCE_VERSION" \
        --arg commitmessage "$COMMIT_MESSAGE" \
        --arg msg "$TF_PLAN_TEXT" \
        --arg url "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/$CODEPIPELINE_NAME/view?region=$AWS_REGION" \
        '{"text":"Plan for pipeline `\($pipeline)` in region `\($region)`\n\n```\($commitid) \($commitmessage)\n\($msg)...```\n\($url)"}')
      echo "$SLACK_PAYLOAD"
      curl \
        -X POST \
        -H 'Content-type: application/json; charset=utf-8' \
        --data "$SLACK_PAYLOAD" \
        "$TF_VAR_PLAN_SLACK_WEBHOOK_URL"
    fi
  fi
}
post_plan_to_slack
