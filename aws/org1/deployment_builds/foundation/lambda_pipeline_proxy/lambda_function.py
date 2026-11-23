"""
Lambda Pipeline Execution Proxy

Provides a secure way to trigger CodePipeline executions WITHOUT allowing
source revision overrides. This prevents agents from triggering pipelines
with malicious commits.

Security features:
- Explicitly rejects sourceRevisionOverride parameter
- Validates pipeline exists before attempting execution
- Checks for active executions to prevent queue overflow
- Minimal IAM permissions (only codepipeline:StartPipelineExecution)
"""

import json
import os
import re
from datetime import datetime
from typing import Any, Dict, List, Optional

import boto3
from botocore.exceptions import ClientError, BotoCoreError


# Initialize CodePipeline client
# We use a module-level client for connection reuse across invocations
codepipeline = boto3.client("codepipeline")

# Maximum number of active executions allowed before rejecting new requests
MAX_ACTIVE_EXECUTIONS = 2

# Pipeline name validation pattern (alphanumeric, underscores, and hyphens)
PIPELINE_NAME_PATTERN = re.compile(r"^[A-Za-z0-9._-]{1,100}$")


def create_response(
    status_code: int,
    body: Dict[str, Any],
    additional_headers: Optional[Dict[str, str]] = None,
) -> Dict[str, Any]:
    """Create a standardized API Gateway response."""
    headers = {
        "Content-Type": "application/json",
        "X-Request-ID": datetime.utcnow().isoformat(),
    }
    if additional_headers:
        headers.update(additional_headers)

    return {
        "statusCode": status_code,
        "headers": headers,
        "body": json.dumps(body),
    }


def validate_pipeline_name(pipeline_name: str) -> Optional[str]:
    """
    Validate pipeline name format.
    Returns error message if invalid, None if valid.
    """
    if not pipeline_name:
        return "pipelineName is required"

    if not isinstance(pipeline_name, str):
        return "pipelineName must be a string"

    if not PIPELINE_NAME_PATTERN.match(pipeline_name):
        return "pipelineName must be 1-100 characters and contain only alphanumeric characters, underscores, hyphens, and periods"

    return None


def check_pipeline_exists(pipeline_name: str) -> tuple[bool, Optional[str]]:
    """
    Check if a pipeline exists.
    Returns (exists, error_message).
    """
    try:
        codepipeline.get_pipeline(name=pipeline_name)
        return True, None
    except ClientError as e:
        error_code = e.response.get("Error", {}).get("Code", "Unknown")
        if error_code == "PipelineNotFoundException":
            return False, f"Pipeline '{pipeline_name}' does not exist"
        return False, f"Error checking pipeline: {str(e)}"
    except BotoCoreError as e:
        return False, f"Error checking pipeline: {str(e)}"


def get_active_executions(pipeline_name: str) -> tuple[int, Optional[str]]:
    """
    Get count of active executions for a pipeline.
    Returns (count, error_message).
    """
    try:
        response = codepipeline.list_pipeline_executions(
            pipelineName=pipeline_name,
            filter={"succeededInStage": {}},  # Filter returns all statuses
        )

        # Count executions that are not in a terminal state
        active_count = 0
        for execution in response.get("pipelineExecutionSummaries", []):
            status = execution.get("status", "")
            if status in ("InProgress", "Stopping"):
                active_count += 1

        return active_count, None

    except ClientError as e:
        error_code = e.response.get("Error", {}).get("Code", "Unknown")
        if error_code == "PipelineNotFoundException":
            return 0, f"Pipeline '{pipeline_name}' does not exist"
        return 0, f"Error checking executions: {str(e)}"
    except BotoCoreError as e:
        return 0, f"Error checking executions: {str(e)}"


def start_pipeline_execution(
    pipeline_name: str,
) -> tuple[Optional[str], Optional[str]]:
    """
    Start a pipeline execution.
    Returns (execution_id, error_message).
    """
    try:
        # Build the request parameters
        # NOTE: We explicitly DO NOT include sourceRevisionOverride or variables for security
        response = codepipeline.start_pipeline_execution(name=pipeline_name)
        return response.get("pipelineExecutionId"), None

    except ClientError as e):
        error_code = e.response.get("Error", {}).get("Code", "Unknown")
        error_message = e.response.get("Error", {}).get("Message", str(e))

        # Handle specific error codes
        if error_code == "PipelineNotFoundException":
            return None, f"Pipeline '{pipeline_name}' does not exist"
        elif error_code == "ValidationException":
            return None, f"Validation error: {error_message}"
        elif error_code == "ConflictException":
            return None, f"Pipeline execution conflict: {error_message}"
        elif error_code == "ThrottlingException":
            return None, "Request throttled by AWS. Please retry."
        else:
            return None, f"Error starting pipeline: {error_message}"

    except BotoCoreError as e:
        return None, f"Error starting pipeline: {str(e)}"


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for pipeline execution requests.

    Expected event format (API Gateway integration):
    {
        "body": "{\"pipelineName\": \"my-pipeline\", ...}"
    }

    Expected body format:
    {
        "pipelineName": "string"  // Required
    }

    Response format:
    {
        "executionId": "string",
        "pipelineName": "string",
        "status": "Started"
    }
    """
    # Log request for debugging
    request_id = context.aws_request_id if context else "unknown"
    print(f"[{request_id}] Received request: {json.dumps(event, default=str)}")

    # Parse request body from API Gateway event
    try:
        body_str = event.get("body", "{}")
        if isinstance(body_str, str):
            body = json.loads(body_str)
        else:
            body = body_str or {}
    except json.JSONDecodeError as e:
        print(f"[{request_id}] Invalid JSON in request body: {e}")
        return create_response(
            400,
            {"error": "Invalid JSON in request body", "code": "INVALID_JSON"},
        )

    # Security check: Explicitly reject if sourceRevisionOverride is present
    if "sourceRevisionOverride" in body:
        print(f"[{request_id}] REJECTED: sourceRevisionOverride parameter detected")
        return create_response(
            403,
            {
                "error": "sourceRevisionOverride is not allowed for security reasons",
                "code": "FORBIDDEN_PARAMETER",
            },
        )

    # Security: Reject if variables parameter is present
    if "variables" in body:
        print(f"[{request_id}] REJECTED: variables parameter detected")
        return create_response(
            403,
            {
                "error": "variables parameter is not allowed for security reasons",
                "code": "FORBIDDEN_PARAMETER",
            },
        )

    # Extract and validate pipeline name
    pipeline_name = body.get("pipelineName")
    error = validate_pipeline_name(pipeline_name)
    if error:
        print(f"[{request_id}] Validation error: {error}")
        return create_response(400, {"error": error, "code": "VALIDATION_ERROR"})

    # Check if pipeline exists
    exists, error = check_pipeline_exists(pipeline_name)
    if not exists:
        print(f"[{request_id}] Pipeline not found: {pipeline_name}")
        return create_response(404, {"error": error, "code": "PIPELINE_NOT_FOUND"})

    # Check for active executions
    active_count, error = get_active_executions(pipeline_name)
    if error and "does not exist" in error:
        # Pipeline was deleted between checks
        return create_response(404, {"error": error, "code": "PIPELINE_NOT_FOUND"})

    if active_count >= MAX_ACTIVE_EXECUTIONS:
        print(f"[{request_id}] Too many active executions: {active_count}")
        return create_response(
            429,
            {
                "error": f"Pipeline has {active_count} active executions (max: {MAX_ACTIVE_EXECUTIONS}). Please wait.",
                "code": "TOO_MANY_EXECUTIONS",
                "activeExecutions": active_count,
            },
        )

    # Start the pipeline execution
    print(f"[{request_id}] Starting pipeline execution for: {pipeline_name}")
    execution_id, error = start_pipeline_execution(pipeline_name)

    if error:
        print(f"[{request_id}] Error starting execution: {error}")
        # Determine appropriate status code based on error
        if "throttled" in error.lower():
            status_code = 429
        elif "does not exist" in error.lower():
            status_code = 404
        elif "validation" in error.lower():
            status_code = 400
        else:
            status_code = 500

        return create_response(
            status_code,
            {"error": error, "code": "EXECUTION_ERROR"},
        )

    # Success response
    print(f"[{request_id}] Successfully started execution: {execution_id}")
    return create_response(
        200,
        {
            "executionId": execution_id,
            "pipelineName": pipeline_name,
            "status": "Started",
            "activeExecutionsBefore": active_count,
        },
    )
