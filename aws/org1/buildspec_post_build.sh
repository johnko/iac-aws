#!/usr/bin/env bash
set -euxo pipefail

set +eu
enable_stage_transition() {
  STAGE_NAME=Plan
  if [[ $CODEPIPELINE_NAME =~ ^CDK-.* ]]; then
    STAGE_NAME=Diff
  fi

  # Try to enable the current pipeline's stage transition if error or No changes to allow the pipeline to resume after pausing for current execution
  aws codepipeline enable-stage-transition \
    --pipeline-name "$CODEPIPELINE_NAME" \
    --stage-name "$STAGE_NAME" \
    --transition-type Inbound
}

if [[ $CODEPIPELINE_NAME =~ ^CDK-.* ]]; then
  # don't enable on CDK_DIFF_EXIT_CODE 2 because it will enable stage transition for current pipeline, which will cause plan to be overwritten by next queued execution
  if [[ -n $CDK_DIFF_EXIT_CODE ]] && [[ $CDK_DIFF_EXIT_CODE != 1 ]]; then
    # CDK_DIFF_EXIT_CODE
    # 0 = Succeeded with empty diff (no changes), need to stop pipeline from going to TerraformApply
    # 1 = Succeeded with non-empty diff (changes present), need to continues pipeline to ApproveOrReject and TerraformApply
    enable_stage_transition
  fi

  if [[ -n $CDK_DEPLOY_EXIT_CODE ]] && [[ $CDK_DEPLOY_EXIT_CODE == 0 ]]; then
    enable_stage_transition
    # error will be handled by EventBridge + Lambda
  fi
else
  # don't enable on TF_PLAN_EXIT_CODE 2 because it will enable stage transition for current pipeline, which will cause plan to be overwritten by next queued execution
  if [[ -n $TF_PLAN_EXIT_CODE ]] && [[ $TF_PLAN_EXIT_CODE != 2 ]]; then
    # TF_PLAN_EXIT_CODE
    # 0 = Succeeded with empty diff (no changes), need to stop pipeline from going to TerraformApply
    # 2 = Succeeded with non-empty diff (changes present), need to continues pipeline to ApproveOrReject and TerraformApply
    # 1 = Error
    enable_stage_transition
  fi

  if [[ -n $TF_APPLY_EXIT_CODE ]] && [[ $TF_APPLY_EXIT_CODE == 0 ]]; then
    enable_stage_transition
    # error will be handled by EventBridge + Lambda
  fi
fi

post_plan_to_slack() {
  if [[ -e $CDK_TMP_LOG ]] && [[ $CDK_TMP_LOG == *diff* ]]; then
    set +ux
    if [[ $CDK_DIFF_EXIT_CODE != 0 ]]; then
      ICON=":hourglass:"
      # use sed to strip escape sequences like color
      # shellcheck disable=SC2002
      CDK_DIFF_TEXT=$(cat "$CDK_TMP_LOG" |
        grep 'Number of stacks with differences' |
        head -c 500)
      SLACK_PAYLOAD=$(jq -n \
        --arg icon "$ICON" \
        --arg url "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/$CODEPIPELINE_NAME/view?region=$AWS_REGION" \
        --arg pipeline "$CODEPIPELINE_NAME" \
        --arg region "$AWS_REGION" \
        --arg commitid "$COMMIT_ID" \
        --arg commitmessage "$COMMIT_MESSAGE" \
        --arg msg "$CDK_DIFF_TEXT" \
        '{"text":"\($icon) Diff for <\($url)|pipeline> `\($pipeline)` in region `\($region)`\n\n```\($commitid) \($commitmessage)\n\n\($msg)```"}')
      echo "$SLACK_PAYLOAD"
      curl \
        -X POST \
        -H 'Content-type: application/json; charset=utf-8' \
        --data "$SLACK_PAYLOAD" \
        "$TF_VAR_PLAN_SLACK_WEBHOOK_URL"
    fi
  elif [[ -e $TF_TMP_LOG ]] && [[ $TF_TMP_LOG == *plan* ]]; then
    set +ux
    if [[ $TF_PLAN_EXIT_CODE != 0 ]]; then
      ICON=":hourglass:"
      # use sed to strip escape sequences like color
      # shellcheck disable=SC2002
      TF_PLAN_TEXT=$(cat "$TF_TMP_LOG" |
        sed 's/\x1b\[[0-9;]*m//g' |
        awk '/^Terraform used the selected providers|^Plan:| Error:/,/^Terraform will perform the following actions|^────────────────────────────────────────────/' |
        grep -v -E '(Terraform used the selected providers to generate|indicated with the following symbols|Terraform will perform the following actions)' |
        sed 's/ 0 to add,//g' |
        sed 's/, 0 to destroy//g' |
        sed 's,──,,g' |
        grep -v -E '^( *|─*)$' |
        head -c 500)
      SLACK_PAYLOAD=$(jq -n \
        --arg icon "$ICON" \
        --arg url "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/$CODEPIPELINE_NAME/view?region=$AWS_REGION" \
        --arg pipeline "$CODEPIPELINE_NAME" \
        --arg region "$AWS_REGION" \
        --arg commitid "$COMMIT_ID" \
        --arg commitmessage "$COMMIT_MESSAGE" \
        --arg msg "$TF_PLAN_TEXT" \
        '{"text":"\($icon) Plan for <\($url)|pipeline> `\($pipeline)` in region `\($region)`\n\n```\($commitid) \($commitmessage)\n\n\($msg)```"}')
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

post_apply_to_slack() {
  if [[ -e $CDK_TMP_LOG ]] && [[ $CDK_TMP_LOG == *deploy* ]]; then
    set +ux
    if [[ $CDK_DEPLOY_EXIT_CODE != 0 ]]; then
      ICON=":x:"
    else
      ICON=":white_check_mark:"
    fi
    # use sed to strip escape sequences like color
    # shellcheck disable=SC2002
    CDK_DEPLOY_TEXT=$(cat "$CDK_TMP_LOG" |
      grep 'Total time' |
      head -c 500)
    SLACK_PAYLOAD=$(jq -n \
      --arg icon "$ICON" \
      --arg url "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/$CODEPIPELINE_NAME/view?region=$AWS_REGION" \
      --arg pipeline "$CODEPIPELINE_NAME" \
      --arg region "$AWS_REGION" \
      --arg commitid "$COMMIT_ID" \
      --arg commitmessage "$COMMIT_MESSAGE" \
      --arg msg "$CDK_DEPLOY_TEXT" \
      '{"text":"\($icon) Deploy for <\($url)|pipeline> `\($pipeline)` in region `\($region)`\n\n```\($commitid) \($commitmessage)\n\n\($msg)```"}')
    echo "$SLACK_PAYLOAD"
    curl \
      -X POST \
      -H 'Content-type: application/json; charset=utf-8' \
      --data "$SLACK_PAYLOAD" \
      "$TF_VAR_PLAN_SLACK_WEBHOOK_URL"
  elif [[ -e $TF_TMP_LOG ]] && [[ $TF_TMP_LOG == *apply* ]]; then
    set +ux
    if [[ $TF_APPLY_EXIT_CODE != 0 ]]; then
      ICON=":x:"
    else
      ICON=":white_check_mark:"
    fi
    # use sed to strip escape sequences like color
    # shellcheck disable=SC2002
    TF_APPLY_TEXT=$(cat "$TF_TMP_LOG" |
      sed 's/\x1b\[[0-9;]*m//g' |
      awk '/^Apply complete| Error:/,/^────────────────────────────────────────────/' |
      sed 's/ 0 added,//g' |
      sed 's/, 0 destroyed//g' |
      head -n1 |
      sed 's,──,,g' |
      grep -v -E '^( *|─*)$' |
      head -c 500)
    SLACK_PAYLOAD=$(jq -n \
      --arg icon "$ICON" \
      --arg url "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/$CODEPIPELINE_NAME/view?region=$AWS_REGION" \
      --arg pipeline "$CODEPIPELINE_NAME" \
      --arg region "$AWS_REGION" \
      --arg commitid "$COMMIT_ID" \
      --arg commitmessage "$COMMIT_MESSAGE" \
      --arg msg "$TF_APPLY_TEXT" \
      '{"text":"\($icon) Apply for <\($url)|pipeline> `\($pipeline)` in region `\($region)`\n\n```\($commitid) \($commitmessage)\n\n\($msg)```"}')
    echo "$SLACK_PAYLOAD"
    curl \
      -X POST \
      -H 'Content-type: application/json; charset=utf-8' \
      --data "$SLACK_PAYLOAD" \
      "$TF_VAR_PLAN_SLACK_WEBHOOK_URL"
  fi
}
post_apply_to_slack
