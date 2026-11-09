# ============================================================================
# Pipeline Common Locals
# ============================================================================
# This module centralizes exit code definitions and state mappings that were
# previously scattered across multiple files as implicit state machines.
#
# Design Principles:
# - NO new infrastructure (no Step Functions, no Lambda changes)
# - Centralize magic numbers into named constants
# - Document the implicit state transitions
# - Provide a single source of truth for pipeline state logic
# ============================================================================

locals {
  # ------------------------------------------------------------------------
  # Exit Code Definitions
  # ------------------------------------------------------------------------
  # These values were previously hardcoded in buildspec YAML files and
  # interpreted by CodePipeline conditional logic. Centralizing them makes
  # the state machine EXPLICIT and self-documenting.

  # Standardized pipeline state outcomes
  pipeline_states = {
    NO_CHANGES    = "no_changes"    # Plan succeeded, empty diff -> skip deploy
    CHANGES_FOUND = "changes_found" # Plan succeeded, has changes -> proceed
    ERROR         = "error"         # Plan failed -> stop pipeline
  }

  # CDK-specific exit codes (cdk diff)
  # Reference: https://docs.aws.amazon.com/cdk/v2/guide/cli.html
  cdk_exit_codes = {
    NO_CHANGES    = "0" # Succeeded with empty diff
    CHANGES_FOUND = "1" # Succeeded with non-empty diff (NOTE: different from TF!)
    ERROR         = "2" # Error during diff
  }

  # Terraform-specific exit codes (terraform plan)
  # Reference: https://developer.hashicorp.com/terraform/cli/commands/plan
  terraform_exit_codes = {
    NO_CHANGES    = "0" # Succeeded with empty diff
    ERROR         = "1" # Error during plan (NOTE: different from CDK!)
    CHANGES_FOUND = "2" # Succeeded with non-empty diff
  }

  # ------------------------------------------------------------------------
  # Exit Code Translation
  # ------------------------------------------------------------------------
  # CDK and Terraform use DIFFERENT exit code conventions:
  #   CDK:        0=nothing, 1=changes, 2=error
  #   Terraform:  0=nothing, 1=error,   2=changes
  #
  # This is confusing! These maps provide a unified view:

  # Translate CDK exit code to standardized state
  cdk_exit_to_state = {
    "0" = local.pipeline_states.NO_CHANGES
    "1" = local.pipeline_states.CHANGES_FOUND
    "2" = local.pipeline_states.ERROR
  }

  # Translate Terraform exit code to standardized state
  terraform_exit_to_state = {
    "0" = local.pipeline_states.NO_CHANGES
    "2" = local.pipeline_states.CHANGES_FOUND
    "1" = local.pipeline_states.ERROR
  }

  # ------------------------------------------------------------------------
  # Stage Names
  # ------------------------------------------------------------------------
  # Stage names vary between CDK and Terraform pipelines.
  # Centralizing prevents drift between code locations.

  stage_names = {
    cdk = {
      plan   = "Diff"
      deploy = "Deploy"
    }
    terraform = {
      plan   = "Plan"
      deploy = "Apply"
    }
  }

  # ------------------------------------------------------------------------
  # Pipeline Name Prefixes
  # ------------------------------------------------------------------------
  # Used by Lambda handlers and event rules to identify pipeline types

  pipeline_prefixes = {
    cdk       = "CDK-"
    terraform = "TF-"
  }

  # ------------------------------------------------------------------------
  # State Transition Types
  # ------------------------------------------------------------------------

  transition_types = {
    inbound  = "Inbound"
    outbound = "Outbound"
  }

  # ------------------------------------------------------------------------
  # Human-Readable State Descriptions
  # ------------------------------------------------------------------------
  # For notifications and logging

  state_descriptions = {
    no_changes = {
      title       = "No Changes Detected"
      description = "The plan stage completed successfully with no infrastructure changes. The deploy stage will be skipped."
      icon        = "✅"
    }
    changes_found = {
      title       = "Changes Pending Approval"
      description = "The plan stage detected infrastructure changes. Awaiting manual approval before proceeding to deploy."
      icon        = "⏳"
    }
    error = {
      title       = "Plan Failed"
      description = "The plan stage encountered an error. Please review the logs for details."
      icon        = "❌"
    }
  }
}

# Outputs for downstream consumers
output "pipeline_states" {
  description = "Standardized pipeline state constants"
  value       = local.pipeline_states
}

output "cdk_exit_codes" {
  description = "CDK-specific exit code definitions"
  value       = local.cdk_exit_codes
}

output "terraform_exit_codes" {
  description = "Terraform-specific exit code definitions"
  value       = local.terraform_exit_codes
}

output "cdk_exit_to_state" {
  description = "Map of CDK exit codes to standardized states"
  value       = local.cdk_exit_to_state
}

output "terraform_exit_to_state" {
  description = "Map of Terraform exit codes to standardized states"
  value       = local.terraform_exit_to_state
}

output "stage_names" {
  description = "Stage name mappings for CDK and Terraform pipelines"
  value       = local.stage_names
}

output "pipeline_prefixes" {
  description = "Pipeline name prefixes for identification"
  value       = local.pipeline_prefixes
}

output "state_descriptions" {
  description = "Human-readable descriptions of pipeline states"
  value       = local.state_descriptions
}
