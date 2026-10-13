locals {
  FullRepositoryId      = "johnko/iac-aws"
  workspace_path_prefix = "aws/org1/"
  aws_terraform_pipelines = {
    # find aws -type f -name _import.sh | sort | xargs dirname | sed 's,aws/org1/,,' | awk '{print "\""$1"\" = {}"}'
    "deployment_builds/cachedependencies" = {
      # DetectChanges = false
      EnvironmentVariables = {
        TF_VAR_aws_account_id = var.aws_account_id_deployment_builds
      }
      RequireManualApproval = false
    }
    "deployment_builds/chatbotcommon" = {
      EnvironmentVariables = {
        TF_VAR_aws_account_id = var.aws_account_id_deployment_builds
      }
      RequireManualApproval = false
    }
    "deployment_builds/foundation" = {
      EnvironmentVariables = {
        TF_VAR_aws_account_id = var.aws_account_id_deployment_builds
      }
    }
    "deployment_builds/pipelinesawscdk" = {
      EnvironmentVariables = {
        TF_VAR_aws_account_id = var.aws_account_id_deployment_builds
      }
      RequireManualApproval = false
    }
    "deployment_builds/pipelinesawsterraform" = {
      EnvironmentVariables = {
        TF_VAR_aws_account_id = var.aws_account_id_deployment_builds
      }
      RequireManualApproval = false
    }
    "prod_management/foundation" = {
      EnvironmentVariables = {
        TF_VAR_aws_account_id = var.aws_account_id_management
      }
    }
    "playground_rswea/foundation" = {
      EnvironmentVariables = {
        TF_VAR_aws_account_id = var.aws_account_id_playground_rswea
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
    "${local.codepipeline_primary_region}"   = false
    "${local.codepipeline_secondary_region}" = true
  }

  regional_pipelines = merge(values({
    for r in [local.codepipeline_primary_region, local.codepipeline_secondary_region] : r => {
      for k, v in local.aws_terraform_pipelines : "${r}/${k}" => merge(
        v,
        {
          "codepipeline_name" : "TF-aws-${replace(k, "/", "-")}"
          "path" : k,
          "region" : r,
          "codebuild_suffix" : local.codebuild_terraform_suffix_by_region[r],
          "DetectChanges" : lookup(v, "DetectChanges", local.DetectChanges_by_region[r]),
        }
      )
    }
  })...)
}

resource "aws_iam_role" "CodePipelineRole" {
  name = "CodePipelineRole-TerraformPipelines"
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
          for k, v in module.s3_codepipeline : [
            v.bucket.arn,
            "${v.bucket.arn}/*",
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
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/codepipeline/TF-*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/codepipeline/TF-*:*"
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
          for v in concat(values(aws_codebuild_project.aws_terraform_plan), values(aws_codebuild_project.aws_terraform_apply)) :
          replace(
            replace(
              replace(
                v.arn,
                local.codebuild_terraform_suffix_by_region[local.codepipeline_primary_region],
                "*"
              ),
              local.codebuild_terraform_suffix_by_region[local.codepipeline_secondary_region],
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

resource "aws_codepipeline" "terraform" {
  for_each = local.regional_pipelines

  region = each.value.region

  name     = each.value.codepipeline_name
  role_arn = aws_iam_role.CodePipelineRole.arn

  execution_mode = "SUPERSEDED" # OR "QUEUED"
  pipeline_type  = "V2"

  artifact_store {
    location = module.s3_codepipeline[each.value.region].bucket.id
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
              ".github/tf.sh",
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
    name = "Plan"

    action {
      category         = "Build"
      input_artifacts  = lookup(each.value, "SecondFullRepositoryId", null) != null ? ["SourceOutput", "SecondSourceOutput"] : ["SourceOutput"]
      name             = "TerraformPlan"
      namespace        = "TerraformPlan"
      output_artifacts = ["TerraformPlanOutput"]
      owner            = "AWS"
      provider         = "CodeBuild" # Can't use Commands until terraform-aws-provider supports it
      run_order        = 1
      version          = "1"
      configuration = {
        PrimarySource = "SourceOutput"
        ProjectName   = "AWSTerraformPlan-${each.value.EnvironmentVariables["TF_VAR_aws_account_id"]}-${each.value.codebuild_suffix}"
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
                value = local.codebuild_terraform_types[each.value.codebuild_suffix].type
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

  stage {
    name = "Apply"

    before_entry {
      condition {
        result = "SKIP"
        rule {
          configuration = {
            Operator = "EQ"
            Value    = "2"
            Variable = "#{TerraformPlan.TF_PLAN_EXIT_CODE}"
            # 0 = Succeeded with empty diff (no changes), need to stop pipeline from going to TerraformApply
            # 2 = Succeeded with non-empty diff (changes present), need to continues pipeline to ApproveOrReject and TerraformApply
            # 1 = Error
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
          "CustomData" : "Last chance to cancel if the TerraformPlan looks wrong! Please REJECT if you're unsure. Only APPROVE if you are 100% sure.",
          "ExternalEntityLink" : "https://github.com/${local.FullRepositoryId}"
        }
      }
    }

    action {
      category        = "Build"
      input_artifacts = ["TerraformPlanOutput"] # use files from Plan stage TerraformPlan action which include a tfplan.tfplan
      name            = "TerraformApply"
      namespace       = "TerraformApply"
      owner           = "AWS"
      provider        = "CodeBuild" # Can't use Commands until terraform-aws-provider supports it
      run_order       = 3
      version         = "1"
      configuration = {
        ProjectName = "AWSTerraformApply-${each.value.EnvironmentVariables["TF_VAR_aws_account_id"]}-${each.value.codebuild_suffix}"
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
                value = local.codebuild_terraform_types[each.value.codebuild_suffix].type
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

}
