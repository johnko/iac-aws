# Pipeline Common Module

This module centralizes pipeline state definitions that were previously implicit and scattered across multiple files.

## The Problem: Implicit State Machines

The iac-aws repository contained **5 implicit state machines**:

### 1. CDK Pipeline State Machine
**File**: `aws/org1/deployment_builds/pipelinesawscdk/codepipeline_aws_cdk_pipelines.tf`

```
Source ──▶ Diff ──▶ [Conditional Check] ──▶ Deploy
                     │
          CDK_DIFF_EXIT_CODE
          ├── 0 (empty) ──▶ SKIP Deploy
          ├── 1 (has changes) ──▶ PROCEED
          └── 2 (error) ──▶ FAIL
```

### 2. Terraform Pipeline State Machine
**File**: `aws/org1/deployment_builds/pipelinesawsterraform/codepipeline_aws_terraform_pipelines.tf`

```
Source ──▶ Plan ──▶ [Conditional Check] ──▶ Apply
                    │
          TF_PLAN_EXIT_CODE
          ├── 0 (empty) ──▶ SKIP Apply
          ├── 2 (has changes) ──▶ PROCEED
          └── 1 (error) ──▶ FAIL
```

> ⚠️ **Note**: CDK and Terraform use DIFFERENT exit codes!
> - CDK: 0=empty, 1=changes, 2=error
> - Terraform: 0=empty, 2=changes, 1=error

### 3. CDK Exit Code State Machine
**File**: `aws/org1/buildspec_aws_cdk_diff.yaml`

```yaml
post_build:
  commands:
    # 0 = No changes, skip Deploy
    # 1 = Changes present, proceed to Deploy
    # 2 = Error, fail the pipeline
    - |
      if [[ $CDK_DIFF_EXIT_CODE != 1 ]]; then
        exit $CDK_DIFF_EXIT_CODE
      fi
```

### 4. Terraform Exit Code State Machine
**File**: `aws/org1/buildspec_aws_terraform_plan.yaml`

```yaml
post_build:
  commands:
    # 0 = No changes, skip Apply
    # 2 = Changes present, proceed to Apply
    # 1 = Error, fail the pipeline
    - |
      if [[ $TF_PLAN_EXIT_CODE != 2 ]]; then
        exit $TF_PLAN_EXIT_CODE
      fi
```

### 5. Approval Rejection Recovery State Machine
**Files**: `lambda/cdk_codepipeline_rejected.py`, `lambda/terraform_codepipeline_rejected.py`

```
CloudWatch Event ──▶ SNS ──▶ Lambda
                                 │
                    ┌────────────┴────────────┐
                    ▼                         ▼
            Pipeline name starts         Pipeline name doesn't
            with "CDK-" or "TF-"         match
                    │                         │
                    ▼                         ▼
            Re-enable stage              Do nothing
            transition
```

## The Solution: Centralized Definitions

This module provides a **single source of truth** for all pipeline state definitions without adding new infrastructure.

### Usage

```hcl
module "pipeline_common" {
  source = "../../modules/pipeline-common"
}

# Reference exit codes consistently
locals {
  my_stage_condition = module.pipeline_common.cdk_exit_codes.NO_CHANGES
}
```

### Centralized Exit Codes

| State | CDK | Terraform | Unified |
|-------|-----|-----------|---------|
| No changes | `"0"` | `"0"` | `no_changes` |
| Has changes | `"1"` | `"2"` | `changes_found` |
| Error | `"2"` | `"1"` | `error` |

### Benefits

- **UX**: Consistent state descriptions for notifications
- **DX**: Single source of truth for exit codes
- **AX**: Self-documenting, no grep required

## No Infrastructure Changes

This module:
- ✅ Centralizes definitions in pure Terraform locals
- ❌ Does NOT create Step Functions
- ❌ Does NOT modify Lambda code
- ❌ Does NOT change CodePipeline flow
- ✅ Provides documentation reference
- ✅ Enables future migration path

## Migration Guide (Optional)

To use the centralized definitions in existing files:

1. Replace hardcoded exit codes:
   ```hcl
   # From:
   cdk_diff_exit_codes = {
     NO_CHANGES = "0"
   }
   
   # To:
   cdk_diff_exit_codes = module.pipeline_common.cdk_exit_codes
   ```

2. Reference stage names consistently:
   ```hcl
   # From:
   TARGET_STAGE_NAME = "Diff"
   
   # To:
   TARGET_STAGE_NAME = module.pipeline_common.stage_names.cdk.plan
   ```

## For AI Agents

When working with pipeline state logic:

1. **Check this module first** for exit code definitions
2. **Use the translation maps** (`cdk_exit_to_state`, `terraform_exit_to_state`) for unified logic
3. **Reference `state_descriptions`** for human-readable messages
4. **Stage names** are in `stage_names.{cdk|terraform}.{plan|deploy}`
