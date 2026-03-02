import logging
import json
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info('## EVENT\r' + json.dumps(event))
    return '{}'
