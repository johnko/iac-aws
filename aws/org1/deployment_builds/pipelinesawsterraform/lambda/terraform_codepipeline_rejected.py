"""
Lambda handler for Terraform CodePipeline rejected/failed events.

IMPLICIT STATE MACHINE:
This handler implements an implicit state machine:

CloudWatch Event ──▶ SNS ──▶ Lambda
                                 │
                    ┌────────────┴────────────┐
                    ▼                         ▼
            Pipeline name starts         Pipeline name doesn't
            with "TF-"?                    match
                    │                         │
                    ▼                         ▼
            Re-enable "Plan"               Ignore event
            stage transition                  │
                    │                         │
                    └────────────┬─────────────┘
                                 ▼
                          Return result

Purpose:
Re-enables the Plan stage transition when an approval is rejected or a build
fails. This prevents the next queued execution from wiping the Plan output
before it can be reviewed.

Stage Transition Pattern:
1. Plan stage runs and outputs Terraform plan results
2. When a new execution starts, CodePipeline disables the inbound transition
   to the Plan stage (by default in V2 pipelines)
3. If approval is rejected, the Plan stage transition must be re-enabled
   so the next execution doesn't overwrite the plan that was rejected

Configuration:
- TARGET_STAGE_NAME = "Plan" (see modules/pipeline-common/locals.tf)
- PIPELINE_PREFIX = "TF-" (see modules/pipeline-common/locals.tf)
- TRANSITION_TYPE_INBOUND = "Inbound"
"""

import logging
import json
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client("codepipeline")

# Configuration constants for the stage transition pattern
TARGET_STAGE_NAME = "Plan"
TRANSITION_TYPE_INBOUND = "Inbound"
PIPELINE_PREFIX = "TF-"
FAILED_STATE = "FAILED"


def lambda_handler(event, context):
    for i in event["Records"]:
        msg = json.loads(i["Sns"]["Message"])
        detail = msg["detail"]
        logger.info(detail)
        logger.info("")
        if (
            detail.get("state") == FAILED_STATE
            and detail.get("pipeline", "").startswith(PIPELINE_PREFIX)
        ):
            logger.info(f"category: {detail['type']['category']}")
            logger.info(f"provider: {detail['type']['provider']}")
            logger.info(f"action: {detail['action']}")
            logger.info(f"state: {detail['state']}")
            pipeline_name = detail["pipeline"]
            logger.info(f"pipeline_name: {pipeline_name}")
            region = detail["region"]
            logger.info(f"region: {region}")
            logger.info("")
            stage_name = TARGET_STAGE_NAME
            transition_type = TRANSITION_TYPE_INBOUND
            logger.info(
                f"Attempting to enable '{transition_type}' transition for stage '{stage_name}' in pipeline '{pipeline_name}'..."
            )
            try:
                response = client.enable_stage_transition(
                    pipelineName=pipeline_name,
                    stageName=stage_name,
                    transitionType=transition_type,
                )
                logger.info(response)
                logger.info(
                    f"Successfully enabled '{transition_type}' transition for stage '{stage_name}' in pipeline '{pipeline_name}'."
                )
            except client.exceptions.PipelineNotFoundException:
                logger.error(f"Error: Pipeline '{pipeline_name}' not found.")
            except client.exceptions.StageNotFoundException:
                logger.error(
                    f"Error: Stage '{stage_name}' not found in pipeline '{pipeline_name}'."
                )
            except Exception as e:
                logger.error(f"An unexpected error occurred: {e}")
    return "{}"
