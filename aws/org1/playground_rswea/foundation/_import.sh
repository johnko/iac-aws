#!/usr/bin/env bash
set -euxo pipefail

export AWS_REGION=us-east-2
terraform import aws_cloudformation_stack.quicksetup_local_deployment_roles "AWS-QuickSetup-SSM-LocalDeploymentRolesStack" || echo "Resource already exists in state or does not exist in AWS"
