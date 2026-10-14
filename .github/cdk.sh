#!/usr/bin/env bash
set -eo pipefail

if [[ -e .envrc ]]; then
  set +x
  # hide secret env values from output
  # shellcheck disable=SC1091
  source .envrc
fi

if [[ -z $IAC_BIN ]]; then
  set -x
  export IAC_BIN=cdk
  set +x
fi

WORKSPACE="$1"
if [[ -z $WORKSPACE ]]; then
  echo "ERROR: missing 'WORKSPACE' as 1st argument"
  exit 1
fi
if [[ ! -d $WORKSPACE ]]; then
  echo "ERROR: invalid 'WORKSPACE', received '$WORKSPACE'"
  exit 1
fi
echo "WORKSPACE=$WORKSPACE"
pushd "$WORKSPACE"

ACTION="$2"
if [[ -z $ACTION ]]; then
  echo "ERROR: missing 'ACTION' as 1st argument"
  exit 1
fi
# transform the action arg into uppercase
SAFE_ACTION=$(echo "$ACTION" | tr '[:lower:]' '[:upper:]')
case $SAFE_ACTION in
  DEPLOY | AUTO | BOOTSTRAP | DIFF | VALIDATE)
    echo "ACTION=$ACTION"
    ;;
  *)
    echo "ERROR: invalid 'ACTION', received '$ACTION'"
    exit 1
    ;;
esac
echo "SAFE_ACTION=$SAFE_ACTION"

# Load above workspace specific secrets
if [[ -e ../.envrc ]]; then
  set +x
  # hide secret env values from output
  # shellcheck disable=SC1091
  source ../.envrc
fi
# Load workspace specific secrets
if [[ -e .envrc ]]; then
  set +x
  # hide secret env values from output
  # shellcheck disable=SC1091
  source .envrc
fi

# .envrc might have changed WORKSPACE value

popd
echo "WORKSPACE=$WORKSPACE"
pushd "$WORKSPACE"
pwd

if [[ -n $CROSS_ACCOUNT_PIPELINE_IAM_ROLE ]] && [[ -n $TF_VAR_aws_account_id ]]; then
  ROLE_ARN="arn:aws:iam::$TF_VAR_aws_account_id:role/$CROSS_ACCOUNT_PIPELINE_IAM_ROLE"
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
  # Hide command
  set +x
  # Assume the Cross Account Role
  # shellcheck disable=SC2046
  read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<<$(
    aws sts assume-role \
      --role-arn "$ROLE_ARN" \
      --role-session-name "cdk-pipeline" \
      --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
      --output text
  )
  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
  export AWS_SESSION_TOKEN
  echo "Assumed role $ROLE_ARN"
  aws sts get-caller-identity --output text
fi

set -ux

set +e
npm ci
$IAC_BIN bootstrap
CDK_BOOTSTRAP_EXIT_CODE=$?
set +x
if [[ "BOOTSTRAP" == "$SAFE_ACTION" || "0" != "$CDK_BOOTSTRAP_EXIT_CODE" ]]; then
  set -x
  set -e
  exit $CDK_BOOTSTRAP_EXIT_CODE
fi

set -x
set +e
$IAC_BIN validate --unstable=validate
CDK_VALIDATE_EXIT_CODE=$?
set +x
if [[ "VALIDATE" == "$SAFE_ACTION" || "0" != "$CDK_VALIDATE_EXIT_CODE" ]]; then
  set -x
  set -e
  exit $CDK_VALIDATE_EXIT_CODE
fi

set +x
if [[ "DEPLOY" == "$SAFE_ACTION" || "AUTO" == "$SAFE_ACTION" || "DIFF" == "$SAFE_ACTION" ]]; then
  if [[ -e _import.sh ]]; then
    set -x
    bash -ex _import.sh
    CDK_IMPORT_EXIT_CODE=$?
    set -e
    if [[ $CDK_IMPORT_EXIT_CODE != 0 ]]; then
      exit $CDK_IMPORT_EXIT_CODE
    fi
  fi
fi

set +x
if [[ "DIFF" == "$SAFE_ACTION" ]]; then
  set -x
  set +e
  $IAC_BIN diff --fail
  CDK_DIFF_EXIT_CODE=$?
  # 0 = Succeeded with empty diff (no changes), need to stop pipeline from going to CDKDeploy
  # 1 = Succeeded with non-empty diff (changes present), need to continues pipeline to ApproveOrReject and CDKDeploy
  set -e
  exit $CDK_DIFF_EXIT_CODE
fi

set +x
if [[ "DEPLOY" == "$SAFE_ACTION" || "AUTO" == "$SAFE_ACTION" ]]; then
  if [[ -e _pre_deploy.sh ]]; then
    set -x
    bash -ex _pre_deploy.sh
    CDK_PRE_DEPLOY_EXIT_CODE=$?
    set -e
    if [[ $CDK_PRE_DEPLOY_EXIT_CODE != 0 ]]; then
      exit $CDK_PRE_DEPLOY_EXIT_CODE
    fi
  fi
  AUTO_APPROVE_ARG=""
  if [[ "AUTO" == "$SAFE_ACTION" ]]; then
    AUTO_APPROVE_ARG="--require-approval never"
  fi
  set -x
  set +e
  $IAC_BIN deploy --all $AUTO_APPROVE_ARG
  CDK_DEPLOY_EXIT_CODE=$?
  set -e
  exit $CDK_DEPLOY_EXIT_CODE
fi

popd
