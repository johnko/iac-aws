locals {
  FullRepositoryId      = "johnko/iac-aws"
  workspace_path_prefix = "aws/org1/"
  pipelines = {
    # find aws -type f -name _import.sh | sort | xargs dirname | sed 's,aws/org1/,,' | awk '{print "\""$1"\" = {}"}'
    "deployment_builds/chatbotcommon" = {
      EnvironmentVariables = {
        TF_VAR_aws_account_id = var.aws_account_id_deployment_builds
      }
    }
    "deployment_builds/foundation" = {
      EnvironmentVariables = {
        TF_VAR_aws_account_id = var.aws_account_id_deployment_builds
      }
    }
    "deployment_builds/pipelinecommon" = {
      EnvironmentVariables = {
        TF_VAR_aws_account_id = var.aws_account_id_deployment_builds
      }
    }
    "prod_management/foundation" = {
      EnvironmentVariables = {
        TF_VAR_aws_account_id = var.aws_account_id_management
      }
    }
    "sandbox_bedrock/foundation" = {
      EnvironmentVariables = {
        TF_VAR_aws_account_id = var.aws_account_id_sandbox_bedrock
      }
    }
    "security_aggregator/foundation" = {
      EnvironmentVariables = {
        TF_VAR_aws_account_id = var.aws_account_id_security_aggregator
      }
    }
    "security_cloudtrail/foundation" = {
      EnvironmentVariables = {
        TF_VAR_aws_account_id = var.aws_account_id_security_cloudtrail
      }
    }
  }

  DetectChanges_by_region = {
    "${local.primary_region}"   = false
    "${local.secondary_region}" = true
  }

  regional_pipelines = merge(values({
    for r in [local.primary_region, local.secondary_region] : r => {
      for k, v in local.pipelines : "${r}/${k}" => merge(
        v,
        {
          "path" : k,
          "region" : r,
          "codebuild_suffix" : local.codebuild_suffix_by_region[r],
          "DetectChanges" : local.DetectChanges_by_region[r],
        }
      )
    }
  })...)
}

resource "aws_iam_role" "CodePipelineRole" {
  name = "CodePipelineStarterTemplate-Terraf-CodePipelineRole-cEfdjyiSFHAA"
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
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ],
        "Resource" : flatten([
          for k, v in aws_s3_bucket.codepipeline : [v.arn, "${v.arn}/*"]
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
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/codepipeline/TF-*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/codepipeline/TF-*:log-stream:*"
        ],
        "Effect" : "Allow"
      },
      {
        # See https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-CodeBuild.html#edit-role-codebuild
        "Action" : [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:BatchGetBuildBatches",
          "codebuild:StartBuildBatch"
        ],
        "Resource" : [
          for k, v in aws_codebuild_project.terraform_plan : v.arn
        ],
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policies_exclusive" "CodePipelineRole" {
  role_name    = aws_iam_role.CodePipelineRole.name
  policy_names = [resource.aws_iam_role_policy.CodePipelineRoleDefaultPolicy.name]
}

output "regional_pipelines" {
  value = local.regional_pipelines
}

resource "aws_codepipeline" "terraform" {
  for_each = local.regional_pipelines

  region = each.value.region

  name     = "TF-${replace(each.value.path, "/", "-")}"
  role_arn = aws_iam_role.CodePipelineRole.arn

  execution_mode = "QUEUED"
  pipeline_type  = "V2"

  artifact_store {
    location = aws_s3_bucket.codepipeline[each.value.region].id
    type     = "S3"
  }

  dynamic "trigger" {
    for_each = each.value.DetectChanges ? [1] : []

    content {
      provider_type = "CodeStarSourceConnection"
      git_configuration {
        source_action_name = "CodeConnections"
        push {
          branches {
            includes = ["main"]
          }
          file_paths {
            includes = [
              "${local.workspace_path_prefix}${each.value.path}/**",
              "${local.workspace_path_prefix}buildspec_*",
              "${local.workspace_path_prefix}foundation_*",
              "${local.workspace_path_prefix}shared_*",
            ]
          }
        }
      }
    }
  }

  stage {
    name = "Source"

    action {
      name             = "CodeConnections"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        BranchName           = "main"
        ConnectionArn        = aws_codeconnections_connection.johnko.arn
        DetectChanges        = each.value.DetectChanges
        FullRepositoryId     = local.FullRepositoryId
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
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
    name = "Deploy"

    action {
      category        = "Build"
      input_artifacts = ["SourceOutput"]
      name            = "TerraformPlan"
      owner           = "AWS"
      provider        = "CodeBuild" # Can't use Commands until terraform-aws-provider supports it
      run_order       = 1
      version         = "1"
      configuration = {
        ProjectName = "TerraformPlan-${each.value.codebuild_suffix}"
        EnvironmentVariables = jsonencode(
          concat(
            [
              {
                name  = "EXECUTOR_TYPE"
                value = local.codebuild_types[each.value.codebuild_suffix].type
                type  = "PLAINTEXT"
              },
              {
                name  = "WORKSPACE_PATH"
                value = "${local.workspace_path_prefix}${each.value.path}"
                type  = "PLAINTEXT"
              },
            ],
            [
              for k, v in each.value.EnvironmentVariables : {
                name  = k,
                value = v
                type  = "PLAINTEXT"
              }
          ])
        )
      }
    }

    action {
      category  = "Approval"
      name      = "ApproveOrReject"
      owner     = "AWS"
      provider  = "Manual"
      run_order = 2
      version   = "1"
      configuration = {
        # See https://docs.aws.amazon.com/codepipeline/latest/userguide/structure-configuration-examples.html
        "CustomData" : "Last chance to cancel if the TerraformPlan looks wrong!",
      }
    }
  }

  action {
    category        = "Build"
    input_artifacts = ["SourceOutput"]
    name            = "TerraformApply"
    owner           = "AWS"
    provider        = "CodeBuild" # Can't use Commands until terraform-aws-provider supports it
    run_order       = 3
    version         = "1"
    configuration = {
      ProjectName = "TerraformApply-${each.value.codebuild_suffix}"
      EnvironmentVariables = jsonencode(
        concat(
          [
            {
              name  = "EXECUTOR_TYPE"
              value = local.codebuild_types[each.value.codebuild_suffix].type
              type  = "PLAINTEXT"
            },
            {
              name  = "WORKSPACE_PATH"
              value = "${local.workspace_path_prefix}${each.value.path}"
              type  = "PLAINTEXT"
            },
          ],
          [
            for k, v in each.value.EnvironmentVariables : {
              name  = k,
              value = v
              type  = "PLAINTEXT"
            }
        ])
      )
    }
  }

}
