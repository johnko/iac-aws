locals {
  FullRepositoryId      = "johnko/iac-aws"
  workspace_path_prefix = "aws/org1/"
  pipelines = {
    # find aws -type f -name _import.sh | sort | xargs dirname | sed 's,aws/org1/,,' | awk '{print "\""$1"\" = {}"}'
    "deployment_builds/chatbotcommon"  = {}
    "deployment_builds/foundation"     = {}
    "deployment_builds/pipelinecommon" = {}
    "prod_management/foundation"       = {}
    "sandbox_bedrock/foundation"       = {}
    "security_aggregator/foundation"   = {}
    "security_cloudtrail/foundation"   = {}
  }
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
        "Resource" : [
          "${aws_s3_bucket.codepipeline.arn}",
          "${aws_s3_bucket.codepipeline.arn}/*"
        ],
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

resource "aws_codepipeline" "terraform_plan" {
  for_each = local.pipelines

  name     = "TF-${replace(each.key, "/", "-")}"
  role_arn = aws_iam_role.CodePipelineRole.arn

  execution_mode = "QUEUED"
  pipeline_type  = "V2"

  artifact_store {
    location = aws_s3_bucket.codepipeline.bucket
    type     = "S3"
  }

  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "CodeConnections"
      push {
        branches {
          includes = ["main"]
        }
        file_paths {
          includes = [
            "^${local.workspace_path_prefix}${each.key}/.*",
          ]
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
      version         = "1"
      configuration = {
        ProjectName = "TerraformPlan-container-linux-small"
        EnvironmentVariables = jsonencode([
          {
            name  = "WORKSPACE_PATH",
            value = "${local.workspace_path_prefix}${each.key}",
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

}
