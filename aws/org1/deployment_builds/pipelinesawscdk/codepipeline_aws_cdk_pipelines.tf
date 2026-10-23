locals {
  FullRepositoryId      = "johnko/iac-aws"
  workspace_path_prefix = "aws/org1/"
  aws_cdk_pipelines = {
    "playground_rswea/rswea" = {
      # DetectChanges = false
      EnvironmentVariables = [
        {
          name  = "TF_VAR_aws_account_id"
          value = var.aws_account_id_playground_rswea
          type  = "PLAINTEXT"
        },
        # GitHub configuration when using GitHub Apps
        # (Optional) If not set, Personal Access Token (see README) is used instead
        # Example: "12345678"
        # GITHUB_APP_ID=""
        # Example: "87654321"
        # GITHUB_INSTALLATION_ID=""

        # Restrict access to the Slack app for certain users (comma-separated)
        # (Optional) If not set, all users in the workspace can access the app
        # Example: "U0123456789,U0QWERTYUIO"
        # SLACK_ADMIN_USER_ID_LIST=""
        {
          name  = "SLACK_ADMIN_USER_ID_LIST"
          value = "/rswea/SLACK_ADMIN_USER_ID_LIST"
          type  = "PARAMETER_STORE"
        },

        # Invitation email is sent on deploy to this email.
        # (Optional) If not set, you need to manually create users in Cognito console
        # Example: "foo@example.com"
        # INITIAL_WEBAPP_USER_EMAIL=""
        {
          name  = "INITIAL_WEBAPP_USER_EMAIL"
          value = "/rswea/INITIAL_WEBAPP_USER_EMAIL"
          type  = "PARAMETER_STORE"
        },

        # AWS WAF config.
        # (Optional) If not set, no IP/country restrictions are applied
        # Example: "203.0.113.0/24,198.51.100.0/24"
        # ALLOWED_IPV4_CIDRS=""
        {
          name  = "ALLOWED_IPV4_CIDRS"
          value = "/rswea/ALLOWED_IPV4_CIDRS"
          type  = "PARAMETER_STORE"
        },
        # Example: "2001:db8::/32"
        # ALLOWED_IPV6_CIDRS=""
        # Example: "JP,US"
        # ALLOWED_COUNTRY_CODES=""

        # Additional IAM managed policies to allow access from agents.
        # (Optional) If not set, only minimal policies are attached
        # Example: "AmazonS3ReadOnlyAccess,AmazonDynamoDBReadOnlyAccess"
        # WORKER_ADDITIONAL_POLICIES=""

        # Bedrock Cross-Region Inference profile. Choose from: global, us, eu, apac, jp, au
        # (Optional) If not set, defaults to 'us'
        # NOTE: Models are filtered based on the specified region's CRI profile support.
        # (e.g. to use Opus 4.5, you need to set "global")
        # BEDROCK_CRI_REGION_OVERRIDE=""
        {
          name  = "BEDROCK_CRI_REGION_OVERRIDE"
          value = "us"
          type  = "PLAINTEXT"
        },

        # Use existing VPC instead of creating a new one
        # (Optional) If not set, a new VPC is created
        # Example: "vpc-0123456789abcdef0"
        # VPC_ID=""

        # Stack name suffix # (Optional) If not set, defaults to 'Sandbox'
        # Set this to deploy multiple stacks in the same AWS account or to distinguish different environments
        # Example: "Production"
        # TARGET_ENV=""
      ]
      SecondBranchName = "main"
      # SecondDetectChanges = false
      SecondFullRepositoryId = "johnko/remote-swe-agents"
    }
  }

  DetectChanges_by_region = {
    "${local.codepipeline_primary_region}"   = false
    "${local.codepipeline_secondary_region}" = true
  }

  regional_pipelines = merge(values({
    for r in [local.codepipeline_primary_region, local.codepipeline_secondary_region] : r => {
      for k, v in local.aws_cdk_pipelines : "${r}/${k}" => merge(
        v,
        {
          "codepipeline_name" : "CDK-aws-${replace(k, "/", "-")}"
          "path" : k,
          "region" : r,
          "codebuild_suffix" : local.codebuild_cdk_suffix_by_region[r],
          "DetectChanges" : lookup(v, "DetectChanges", local.DetectChanges_by_region[r]),
        }
      )
    }
  })...)
}

resource "aws_iam_role" "CodePipelineRole" {
  name = "CodePipelineRole-CDKPipelines"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "codepipeline.amazonaws.com"
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "StringEquals" : {
            "aws:SourceAccount" : "${data.aws_caller_identity.current.account_id}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "CodePipelineRoleDefaultPolicy" {
  name = "CodePipelineRoleDefaultPolicy"
  role = aws_iam_role.CodePipelineRole.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceAccount" : "${data.aws_caller_identity.current.account_id}"
          }
        },
        "Action" : [
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
        ],
        "Resource" : flatten([
          for k, v in data.aws_s3_bucket.s3_codepipeline : [
            v.arn,
            "${v.arn}/*",
          ]
        ]),
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "codestar-connections:UseConnection"
        ],
        "Resource" : aws_codeconnections_connection.johnko.arn,
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/codepipeline/CDK-*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/codepipeline/CDK-*:*"
        ],
        "Effect" : "Allow"
      },
      {
        # See https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-CodeBuild.html#edit-role-codebuild
        "Action" : [
          "codebuild:BatchGetBuildBatches",
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:StartBuildBatch",
        ],
        "Resource" : distinct([
          for v in concat(values(aws_codebuild_project.aws_cdk_diff), values(aws_codebuild_project.aws_cdk_deploy)) :
          replace(
            replace(
              replace(
                v.arn,
                local.codebuild_cdk_suffix_by_region[local.codepipeline_primary_region],
                "*"
              ),
              local.codebuild_cdk_suffix_by_region[local.codepipeline_secondary_region],
              "*"
            ),
            "/arn:aws:codebuild:(.*):${data.aws_caller_identity.current.account_id}:project/",
            "arn:aws:codebuild:*:${data.aws_caller_identity.current.account_id}:project"
          )
        ]),
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policies_exclusive" "CodePipelineRole" {
  role_name    = aws_iam_role.CodePipelineRole.name
  policy_names = [aws_iam_role_policy.CodePipelineRoleDefaultPolicy.name]
}

output "regional_pipelines" {
  value = local.regional_pipelines
}

resource "aws_codepipeline" "cdk" {
  for_each = local.regional_pipelines

  region = each.value.region

  name     = each.value.codepipeline_name
  role_arn = aws_iam_role.CodePipelineRole.arn

  execution_mode = "SUPERSEDED" # OR "QUEUED"
  pipeline_type  = "V2"

  artifact_store {
    location = data.aws_s3_bucket.s3_codepipeline[each.value.region].id
    type     = "S3"
  }

  dynamic "trigger" {
    for_each = each.value.DetectChanges ? [1] : []

    content {
      provider_type = "CodeStarSourceConnection"
      git_configuration {
        source_action_name = "CodeConnection1"
        push {
          branches {
            includes = ["main"]
          }
          file_paths {
            includes = [
              ".github/cdk.sh",
              ".envrc",
              "${local.workspace_path_prefix}${each.value.path}/**",
              "${local.workspace_path_prefix}buildspec_*",
              "${local.workspace_path_prefix}foundation_*",
              "${local.workspace_path_prefix}shared_*",
              "modules/**",
            ]
          }
        }
      }
    }
  }

  dynamic "trigger" {
    for_each = lookup(each.value, "SecondFullRepositoryId", null) != null && lookup(each.value, "SecondDetectChanges", each.value.DetectChanges) ? [1] : []

    content {
      provider_type = "CodeStarSourceConnection"
      git_configuration {
        source_action_name = "CodeConnection2"
        push {
          branches {
            includes = [lookup(each.value, "SecondBranchName", "main")]
          }
        }
      }
    }
  }

  stage {
    name = "Source"

    action {
      name             = "CodeConnection1"
      category         = "Source"
      namespace        = "SourceVariables"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      run_order        = 1
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        BranchName           = lookup(each.value, "BranchName", "main")
        ConnectionArn        = aws_codeconnections_connection.johnko.arn
        DetectChanges        = each.value.DetectChanges
        FullRepositoryId     = local.FullRepositoryId
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }

    dynamic "action" {
      for_each = lookup(each.value, "SecondFullRepositoryId", null) != null ? [1] : []

      content {
        name             = "CodeConnection2"
        category         = "Source"
        namespace        = "SecondSourceVariables"
        owner            = "AWS"
        provider         = "CodeStarSourceConnection"
        run_order        = 1
        version          = "1"
        output_artifacts = ["SecondSourceOutput"]

        configuration = {
          BranchName           = lookup(each.value, "SecondBranchName", "main")
          ConnectionArn        = aws_codeconnections_connection.johnko.arn
          DetectChanges        = lookup(each.value, "SecondDetectChanges", each.value.DetectChanges)
          FullRepositoryId     = lookup(each.value, "SecondFullRepositoryId", local.FullRepositoryId)
          OutputArtifactFormat = "CODEBUILD_CLONE_REF"
        }
      }
    }

    on_failure {
      result = "RETRY"

      retry_configuration {
        retry_mode = "ALL_ACTIONS"
      }
    }
  }

  stage {
    name = "Diff"

    action {
      category         = "Build"
      input_artifacts  = lookup(each.value, "SecondFullRepositoryId", null) != null ? ["SourceOutput", "SecondSourceOutput"] : ["SourceOutput"]
      name             = "CDKDiff"
      namespace        = "CDKDiff"
      output_artifacts = ["CDKDiffOutput"]
      owner            = "AWS"
      provider         = "CodeBuild" # Can't use Commands until terraform-aws-provider supports it
      run_order        = 1
      version          = "1"
      configuration = {
        PrimarySource = "SourceOutput"
        ProjectName   = "AWSCDKDiff-${each.value.EnvironmentVariables[0].value}-${each.value.codebuild_suffix}"
        EnvironmentVariables = jsonencode(
          concat(
            [
              {
                name  = "CODEPIPELINE_NAME"
                value = each.value.codepipeline_name
                type  = "PLAINTEXT"
              },
              {
                name  = "COMMIT_ID"
                value = "#{SourceVariables.CommitId}"
                type  = "PLAINTEXT"
              },
              {
                name  = "COMMIT_MESSAGE"
                value = "#{SourceVariables.CommitMessage}"
                type  = "PLAINTEXT"
              },
              {
                name  = "CROSS_ACCOUNT_PIPELINE_IAM_ROLE"
                value = "CrossAccountPipelineRole-TerraformPlan"
                type  = "PLAINTEXT"
              },
              {
                name  = "EXECUTOR_TYPE"
                value = local.codebuild_cdk_types[each.value.codebuild_suffix].type
                type  = "PLAINTEXT"
              },
              {
                name  = "WORKSPACE_PATH"
                value = "${local.workspace_path_prefix}${each.value.path}"
                type  = "PLAINTEXT"
              },
            ],
            each.value.EnvironmentVariables
          )
        )
      }
    }
  }

  stage {
    name = "Deploy"

    before_entry {
      condition {
        result = "SKIP"
        rule {
          configuration = {
            Operator = "EQ"
            Value    = "1"
            Variable = "#{CDKDiff.CDK_DIFF_EXIT_CODE}"
            # 0 = Succeeded with empty diff (no changes), need to stop pipeline from going to CDKDeploy
            # 1 = Succeeded with non-empty diff (changes present), need to continues pipeline to ApproveOrReject and CDKDeploy
          }
          name   = "ChangesPresent"
          region = each.value.region
          rule_type_id {
            category = "Rule"
            owner    = "AWS"
            provider = "VariableCheck"
            version  = "1"
          }
        }
      }
    }

    dynamic "action" {
      for_each = lookup(each.value, "RequireManualApproval", true) == true ? [1] : []

      content {
        category           = "Approval"
        name               = "ApproveOrReject"
        owner              = "AWS"
        provider           = "Manual"
        run_order          = 2
        timeout_in_minutes = 15
        version            = "1"
        configuration = {
          # See https://docs.aws.amazon.com/codepipeline/latest/userguide/structure-configuration-examples.html
          "CustomData" : "Last chance to cancel if the CDKDiff looks wrong! Please REJECT if you're unsure. Only APPROVE if you are 100% sure.",
          "ExternalEntityLink" : "https://github.com/${local.FullRepositoryId}"
        }
      }
    }

    action {
      category        = "Build"
      input_artifacts  = lookup(each.value, "SecondFullRepositoryId", null) != null ? ["CDKDiffOutput", "SecondSourceOutput"] : ["CDKDiffOutput"] # use some files from Diff stage CDKDiff action
      name            = "CDKDeploy"
      namespace       = "CDKDeploy"
      owner           = "AWS"
      provider        = "CodeBuild" # Can't use Commands until terraform-aws-provider supports it
      run_order       = 3
      version         = "1"
      configuration = {
        PrimarySource = "CDKDiffOutput"
        ProjectName = "AWSCDKDeploy-${each.value.EnvironmentVariables[0].value}-${each.value.codebuild_suffix}"
        EnvironmentVariables = jsonencode(
          concat(
            [
              {
                name  = "CODEPIPELINE_NAME"
                value = each.value.codepipeline_name
                type  = "PLAINTEXT"
              },
              {
                name  = "COMMIT_ID"
                value = "#{SourceVariables.CommitId}"
                type  = "PLAINTEXT"
              },
              {
                name  = "COMMIT_MESSAGE"
                value = "#{SourceVariables.CommitMessage}"
                type  = "PLAINTEXT"
              },
              {
                name  = "CROSS_ACCOUNT_PIPELINE_IAM_ROLE"
                value = "CrossAccountPipelineRole-TerraformApply"
                type  = "PLAINTEXT"
              },
              {
                name  = "EXECUTOR_TYPE"
                value = local.codebuild_cdk_types[each.value.codebuild_suffix].type
                type  = "PLAINTEXT"
              },
              {
                name  = "WORKSPACE_PATH"
                value = "${local.workspace_path_prefix}${each.value.path}"
                type  = "PLAINTEXT"
              },
            ],
            each.value.EnvironmentVariables
          )
        )
      }
    }
  }

}
