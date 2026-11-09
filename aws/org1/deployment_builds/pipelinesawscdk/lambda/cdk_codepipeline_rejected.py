"""
Lambda handler for CDK CodePipeline rejected/failed events.

This handler re-enables the Diff stage transition when an approval is rejected
or a build fails. This prevents the next queued execution from wiping the Diff
output before it can be reviewed.

Stage Transition Pattern:
1. Diff stage runs and outputs CDK diff results
2. When a new execution starts, CodePipeline disables the inbound transition
   to the Diff stage (by default in V2 pipelines)
3. If approval is rejected, the Diff stage transition must be re-enabled
   so the next execution doesn't overwrite the diff that was rejected
"""

import logging
import json
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client("codepipeline")

# Configuration constants for the stage transition pattern
TARGET_STAGE_NAME = "Diff"
TRANSITION_TYPE_INBOUND = "Inbound"
PIPELINE_PREFIX = "CDK-"
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
