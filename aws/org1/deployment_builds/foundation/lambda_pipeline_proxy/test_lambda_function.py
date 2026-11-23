"""
Test suite for Lambda Pipeline Execution Proxy

Run tests: pytest test_lambda_function.py -v
"""

import json
import unittest
from unittest.mock import Mock, patch, MagicMock

import lambda_function


class TestLambdaFunction(unittest.TestCase):
    """Test cases for the Lambda handler."""

    def setUp(self):
        """Set up test fixtures."""
        self.mock_context = Mock()
        self.mock_context.aws_request_id = "test-request-id-123"

    def _create_api_event(self, body: dict) -> dict:
        """Helper to create API Gateway event with body."""
        return {"body": json.dumps(body)}

    def test_rejects_source_revision_override(self):
        """Security: Reject requests with sourceRevisionOverride."""
        event = self._create_api_event({
            "pipelineName": "my-pipeline",
            "sourceRevisionOverride": {"actionName": "Source", "revisionType": "COMMIT_ID", "revisionValue": "abc123"}
        })

        response = lambda_function.handler(event, self.mock_context)

        self.assertEqual(response["statusCode"], 403)
        body = json.loads(response["body"])
        self.assertEqual(body["code"], "FORBIDDEN_PARAMETER")
        self.assertIn("sourceRevisionOverride", body["error"])

    def test_rejects_variables_parameter(self):
        """Security: Reject requests with variables."""
        event = self._create_api_event({
            "pipelineName": "my-pipeline",
            "variables": [{"name": "ENV", "value": "prod"}]
        })

        response = lambda_function.handler(event, self.mock_context)

        self.assertEqual(response["statusCode"], 403)
        body = json.loads(response["body"])
        self.assertEqual(body["code"], "FORBIDDEN_PARAMETER")
        self.assertIn("variables", body["error"])

    def test_rejects_both_forbidden_parameters(self):
        """Security: Reject requests with both forbidden parameters."""
        event = self._create_api_event({
            "pipelineName": "my-pipeline",
            "sourceRevisionOverride": {"actionName": "Source", "revisionType": "COMMIT_ID"},
            "variables": [{"name": "ENV", "value": "prod"}]
        })

        response = lambda_function.handler(event, self.mock_context)

        # Should reject on first forbidden parameter found
        self.assertEqual(response["statusCode"], 403)
        body = json.loads(response["body"])
        self.assertEqual(body["code"], "FORBIDDEN_PARAMETER")

    @patch("lambda_function.codepipeline")
    def test_successful_execution(self, mock_codepipeline):
        """Test successful pipeline execution."""
        # Mock responses
        mock_codepipeline.get_pipeline.return_value = {"pipeline": {"name": "my-pipeline"}}
        mock_codepipeline.list_pipeline_executions.return_value = {"pipelineExecutionSummaries": []}
        mock_codepipeline.start_pipeline_execution.return_value = {"pipelineExecutionId": "exec-123"}

        event = self._create_api_event({"pipelineName": "my-pipeline"})

        response = lambda_function.handler(event, self.mock_context)

        self.assertEqual(response["statusCode"], 200)
        body = json.loads(response["body"])
        self.assertEqual(body["executionId"], "exec-123")
        self.assertEqual(body["pipelineName"], "my-pipeline")
        self.assertEqual(body["status"], "Started")
        self.assertEqual(body["activeExecutionsBefore"], 0)

        # Verify start_pipeline_execution was called without sourceRevisionOverride or variables
        mock_codepipeline.start_pipeline_execution.assert_called_once_with(name="my-pipeline")

    def test_missing_pipeline_name(self):
        """Validation: Reject requests without pipelineName."""
        event = self._create_api_event({})

        response = lambda_function.handler(event, self.mock_context)

        self.assertEqual(response["statusCode"], 400)
        body = json.loads(response["body"])
        self.assertEqual(body["code"], "VALIDATION_ERROR")

    def test_invalid_pipeline_name_empty(self):
        """Validation: Reject empty pipelineName."""
        event = self._create_api_event({"pipelineName": ""})

        response = lambda_function.handler(event, self.mock_context)

        self.assertEqual(response["statusCode"], 400)
        body = json.loads(response["body"])
        self.assertEqual(body["code"], "VALIDATION_ERROR")

    def test_invalid_pipeline_name_type(self):
        """Validation: Reject non-string pipelineName."""
        event = self._create_api_event({"pipelineName": 123})

        response = lambda_function.handler(event, self.mock_context)

        self.assertEqual(response["statusCode"], 400)
        body = json.loads(response["body"])
        self.assertEqual(body["code"], "VALIDATION_ERROR")

    def test_invalid_pipeline_name_special_chars(self):
        """Validation: Reject pipelineName with invalid characters."""
        event = self._create_api_event({"pipelineName": "my/pipeline!@#"})

        response = lambda_function.handler(event, self.mock_context)

        self.assertEqual(response["statusCode"], 400)
        body = json.loads(response["body"])
        self.assertEqual(body["code"], "VALIDATION_ERROR")

    @patch("lambda_function.codepipeline")
    def test_pipeline_not_found(self, mock_codepipeline):
        """Edge case: Return 404 when pipeline doesn't exist."""
        from botocore.exceptions import ClientError

        error_response = {"Error": {"Code": "PipelineNotFoundException", "Message": "Pipeline not found"}}
        mock_codepipeline.get_pipeline.side_effect = ClientError(error_response, "GetPipeline")

        event = self._create_api_event({"pipelineName": "nonexistent-pipeline"})

        response = lambda_function.handler(event, self.mock_context)

        self.assertEqual(response["statusCode"], 404)
        body = json.loads(response["body"])
        self.assertEqual(body["code"], "PIPELINE_NOT_FOUND")

    @patch("lambda_function.codepipeline")
    def test_too_many_active_executions(self, mock_codepipeline):
        """Edge case: Reject when too many active executions."""
        # Mock responses
        mock_codepipeline.get_pipeline.return_value = {"pipeline": {"name": "my-pipeline"}}
        # Simulate 3 active executions (max is 2)
        mock_codepipeline.list_pipeline_executions.return_value = {
            "pipelineExecutionSummaries": [
                {"status": "InProgress", "pipelineExecutionId": "exec-1"},
                {"status": "Stopping", "pipelineExecutionId": "exec-2"},
                {"status": "InProgress", "pipelineExecutionId": "exec-3"},
            ]
        }

        event = self._create_api_event({"pipelineName": "my-pipeline"})

        response = lambda_function.handler(event, self.mock_context)

        self.assertEqual(response["statusCode"], 429)
        body = json.loads(response["body"])
        self.assertEqual(body["code"], "TOO_MANY_EXECUTIONS")
        self.assertEqual(body["activeExecutions"], 3)

    @patch("lambda_function.codepipeline")
    def test_completed_executions_not_counted(self, mock_codepipeline):
        """Edge case: Completed executions don't count toward limit."""
        # Mock responses
        mock_codepipeline.get_pipeline.return_value = {"pipeline": {"name": "my-pipeline"}}
        # Only 1 active, 2 completed
        mock_codepipeline.list_pipeline_executions.return_value = {
            "pipelineExecutionSummaries": [
                {"status": "InProgress", "pipelineExecutionId": "exec-1"},
                {"status": "Succeeded", "pipelineExecutionId": "exec-2"},
                {"status": "Failed", "pipelineExecutionId": "exec-3"},
            ]
        }
        mock_codepipeline.start_pipeline_execution.return_value = {"pipelineExecutionId": "exec-4"}

        event = self._create_api_event({"pipelineName": "my-pipeline"})

        response = lambda_function.handler(event, self.mock_context)

        # Should succeed since only 1 active execution
        self.assertEqual(response["statusCode"], 200)

    @patch("lambda_function.codepipeline")
    def test_throttling_exception(self, mock_codepipeline):
        """AWS error handling: Handle throttling."""
        from botocore.exceptions import ClientError

        mock_codepipeline.get_pipeline.return_value = {"pipeline": {"name": "my-pipeline"}}
        mock_codepipeline.list_pipeline_executions.return_value = {"pipelineExecutionSummaries": []}

        error_response = {"Error": {"Code": "ThrottlingException", "Message": "Rate exceeded"}}
        mock_codepipeline.start_pipeline_execution.side_effect = ClientError(error_response, "StartPipelineExecution")

        event = self._create_api_event({"pipelineName": "my-pipeline"})

        response = lambda_function.handler(event, self.mock_context)

        self.assertEqual(response["statusCode"], 429)
        body = json.loads(response["body"])
        self.assertIn("throttled", body["error"].lower())

    @patch("lambda_function.codepipeline")
    def test_validation_exception(self, mock_codepipeline):
        """AWS error handling: Handle validation errors."""
        from botocore.exceptions import ClientError

        mock_codepipeline.get_pipeline.return_value = {"pipeline": {"name": "my-pipeline"}}
        mock_codepipeline.list_pipeline_executions.return_value = {"pipelineExecutionSummaries": []}

        error_response = {"Error": {"Code": "ValidationException", "Message": "Invalid parameter"}}
        mock_codepipeline.start_pipeline_execution.side_effect = ClientError(error_response, "StartPipelineExecution")

        event = self._create_api_event({"pipelineName": "my-pipeline"})

        response = lambda_function.handler(event, self.mock_context)

        self.assertEqual(response["statusCode"], 400)

    def test_invalid_json_body(self):
        """Error handling: Handle invalid JSON in request body."""
        event = {"body": "not valid json{{{"}

        response = lambda_function.handler(event, self.mock_context)

        self.assertEqual(response["statusCode"], 400)
        body = json.loads(response["body"])
        self.assertEqual(body["code"], "INVALID_JSON")

    def test_body_already_dict(self):
        """Handle case where body is already a dict (direct Lambda invocation)."""
        with patch("lambda_function.codepipeline") as mock_codepipeline:
            mock_codepipeline.get_pipeline.return_value = {"pipeline": {"name": "my-pipeline"}}
            mock_codepipeline.list_pipeline_executions.return_value = {"pipelineExecutionSummaries": []}
            mock_codepipeline.start_pipeline_execution.return_value = {"pipelineExecutionId": "exec-456"}

            # Body is already a dict (not JSON string)
            event = {"body": {"pipelineName": "my-pipeline"}}

            response = lambda_function.handler(event, self.mock_context)

            self.assertEqual(response["statusCode"], 200)
            body = json.loads(response["body"])
            self.assertEqual(body["executionId"], "exec-456")


class TestValidationHelpers(unittest.TestCase):
    """Test validation helper functions."""

    def test_validate_pipeline_name_valid(self):
        """Test valid pipeline names."""
        valid_names = [
            "my-pipeline",
            "my_pipeline",
            "my.pipeline",
            "MyPipeline123",
            "a",  # single char
            "a" * 100,  # max length
        ]
        for name in valid_names:
            with self.subTest(name=name):
                result = lambda_function.validate_pipeline_name(name)
                self.assertIsNone(result)

    def test_validate_pipeline_name_invalid(self):
        """Test invalid pipeline names."""
        invalid_names = [
            ("", "empty"),
            ("a" * 101, "too long"),
            ("my/pipeline", "slash"),
            ("my@pipeline", "at symbol"),
            ("my pipeline", "space"),
            ("my!pipeline", "exclamation"),
        ]
        for name, desc in invalid_names:
            with self.subTest(name=name, desc=desc):
                result = lambda_function.validate_pipeline_name(name)
                self.assertIsNotNone(result)


class TestEdgeCases(unittest.TestCase):
    """Additional edge case tests."""

    def test_pipeline_name_exactly_100_chars(self):
        """Boundary: exactly 100 characters is valid."""
        name = "a" * 100
        result = lambda_function.validate_pipeline_name(name)
        self.assertIsNone(result)

    def test_pipeline_name_101_chars(self):
        """Boundary: 101 characters is invalid."""
        name = "a" * 101
        result = lambda_function.validate_pipeline_name(name)
        self.assertIsNotNone(result)

    def test_none_pipeline_name(self):
        """None pipeline name returns error."""
        result = lambda_function.validate_pipeline_name(None)
        self.assertIsNotNone(result)


if __name__ == "__main__":
    unittest.main()
