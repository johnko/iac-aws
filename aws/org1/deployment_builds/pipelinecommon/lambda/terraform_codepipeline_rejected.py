import os
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client('lambda')
client.get_account_settings()


def lambda_handler(event, context):
    logger.info('## ENVIRONMENT VARIABLES\r' + json.dumps(dict(**os.environ)))
    logger.info('## EVENT\r' + json.dumps(event))
    logger.info('## CONTEXT\r' + json.dumps(context))
    response = client.get_account_settings()
    return response['AccountUsage']
