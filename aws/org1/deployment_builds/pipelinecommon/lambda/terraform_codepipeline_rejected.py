import logging
import json
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client("codepipeline")


def lambda_handler(event, context):
    # logger.info('## EVENT\n' + json.dumps(event))
    # logger.info('## PARSED\n')
    for i in event["Records"]:
        msg = json.loads(i["Sns"]["Message"])
        detail = msg["detail"]
        logger.info(detail)
        logger.info("")
        if (
            detail["state"]
            and detail["state"] == "FAILED"
            and detail["pipeline"].startswith("TF-")
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
            stage_name = "Plan"
            transition_type = "Inbound"
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
