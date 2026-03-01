locals {
  pipelines = {
    # find aws -type f -name _import.sh | sort | xargs dirname | sed 's,aws/org1/,,' | tr / - | awk '{print "\""$1"\" = {}"}'
    "deployment_builds-chatbotcommon"  = {}
    "deployment_builds-foundation"     = {}
    "deployment_builds-pipelinecommon" = {}
    "prod_management-foundation"       = {}
    "sandbox_bedrock-foundation"       = {}
    "security_aggregator-foundation"   = {}
    "security_cloudtrail-foundation"   = {}
  }
}

# resource "aws_iam_role" "terraform_pipelines" {
#   name = "CodePipelineStarterTemplate-Terraf-CodePipelineRole-cEfdjyiSFHAA"
#   assume_role_policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Effect" : "Allow",
#         "Principal" : {
#           "Service" : "codepipeline.amazonaws.com"
#         },
#         "Action" : "sts:AssumeRole",
#         "Condition" : {
#           "StringEquals" : {
#             "aws:SourceAccount" : "${data.aws_caller_identity.current.account_id}"
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy" "CodePipelineRoleDefaultPolicy" {
#   name = "CodePipelineRoleDefaultPolicy"
#   role = aws_iam_role.chatbot_user[each.key].id

#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Condition" : {
#           "StringEquals" : {
#             "aws:ResourceAccount" : "${data.aws_caller_identity.current.account_id}"
#           }
#         },
#         "Action" : [
#           "s3:PutObject",
#           "s3:GetObject",
#           "s3:GetObjectVersion",
#           "s3:GetBucketVersioning",
#           "s3:GetBucketAcl",
#           "s3:GetBucketLocation"
#         ],
#         "Resource" : [
#           "${aws_s3_bucket.codepipeline.arn}",
#           "${aws_s3_bucket.codepipeline.arn}/*"
#         ],
#         "Effect" : "Allow"
#       },
#       {
#         "Action" : [
#           "codestar-connections:UseConnection"
#         ],
#         "Resource" : aws_codeconnections_connection.johnko.arn,
#         "Effect" : "Allow"
#       },
#       {
#         "Action" : [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ],
#         "Resource" : [
#           "arn:aws:logs:ca-central-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/codepipeline/TF-*",
#           "arn:aws:logs:ca-central-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/codepipeline/TF-*:log-stream:*"
#         ],
#         "Effect" : "Allow"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policies_exclusive" "chatbot_user_inline" {
#   for_each = local.slack_user_roles

#   role_name    = aws_iam_role.chatbot_user[each.key].name
#   policy_names = [resource.aws_iam_role_policy.inline_policy1[each.key].name]
# }


# CodePipelineRoleDefaultPolicy

# resource "aws_codepipeline" "terraform_plan" {
#   # for_each = local.pipelines

#   name     = "TF-deployment_builds-pipelinecommon"
#   role_arn = aws_iam_role.codepipeline_role.arn

#   pipeline_type = "V2"

#   artifact_store {
#     location = aws_s3_bucket.codepipeline_bucket.bucket
#     type     = "S3"

#     encryption_key {
#       id   = data.aws_kms_alias.s3kmskey.arn
#       type = "KMS"
#     }
#   }

#   stage {
#     name = "Source"

#     action {
#       name             = "Source"
#       category         = "Source"
#       owner            = "AWS"
#       provider         = "CodeStarSourceConnection"
#       version          = "1"
#       output_artifacts = ["source_output"]

#       configuration = {
#         ConnectionArn    = aws_codestarconnections_connection.example.arn
#         FullRepositoryId = "my-organization/example"
#         BranchName       = "main"
#       }
#     }
#   }

#   stage {
#     name = "Build"

#     action {
#       name             = "Build"
#       category         = "Build"
#       owner            = "AWS"
#       provider         = "CodeBuild"
#       input_artifacts  = ["source_output"]
#       output_artifacts = ["build_output"]
#       version          = "1"

#       configuration = {
#         ProjectName = "test"
#       }
#     }
#   }

#   stage {
#     name = "Deploy"

#     action {
#       name            = "Deploy"
#       category        = "Deploy"
#       owner           = "AWS"
#       provider        = "CloudFormation"
#       input_artifacts = ["build_output"]
#       version         = "1"

#       configuration = {
#         ActionMode     = "REPLACE_ON_FAILURE"
#         Capabilities   = "CAPABILITY_AUTO_EXPAND,CAPABILITY_IAM"
#         OutputFileName = "CreateStackOutput.json"
#         StackName      = "MyStack"
#         TemplatePath   = "build_output::sam-templated.yaml"
#       }
#     }
#   }
# }

# resource "aws_codestarconnections_connection" "example" {
#   name          = "example-connection"
#   provider_type = "GitHub"
# }

# resource "aws_s3_bucket" "codepipeline_bucket" {
#   bucket = "test-bucket"
# }

# resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pab" {
#   bucket = aws_s3_bucket.codepipeline_bucket.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# data "aws_iam_policy_document" "assume_role" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["codepipeline.amazonaws.com"]
#     }

#     actions = ["sts:AssumeRole"]
#   }
# }

# resource "aws_iam_role" "codepipeline_role" {
#   name               = "test-role"
#   assume_role_policy = data.aws_iam_policy_document.assume_role.json
# }

# data "aws_iam_policy_document" "codepipeline_policy" {
#   statement {
#     effect = "Allow"

#     actions = [
#       "s3:GetObject",
#       "s3:GetObjectVersion",
#       "s3:GetBucketVersioning",
#       "s3:PutObjectAcl",
#       "s3:PutObject",
#     ]

#     resources = [
#       aws_s3_bucket.codepipeline_bucket.arn,
#       "${aws_s3_bucket.codepipeline_bucket.arn}/*"
#     ]
#   }

#   statement {
#     effect    = "Allow"
#     actions   = ["codestar-connections:UseConnection"]
#     resources = [aws_codestarconnections_connection.example.arn]
#   }

#   statement {
#     effect = "Allow"

#     actions = [
#       "codebuild:BatchGetBuilds",
#       "codebuild:StartBuild",
#     ]

#     resources = ["*"]
#   }
# }

# resource "aws_iam_role_policy" "codepipeline_policy" {
#   name   = "codepipeline_policy"
#   role   = aws_iam_role.codepipeline_role.id
#   policy = data.aws_iam_policy_document.codepipeline_policy.json
# }

# # Resources:
# #   CodePipeline:
# #     Type: AWS::CodePipeline::Pipeline
# #     Properties:
# #       ArtifactStore:
# #         Location: !Ref CodePipelineArtifactsBucket
# #         Type: S3
# #       ExecutionMode: QUEUED
# #       Name: !Ref CodePipelineName
# #       PipelineType: V2
# #       RoleArn: !If
# #         - CreatePipelineRole
# #         - !GetAtt CodePipelineRole.Arn
# #         - !Ref PipelineRoleArn
# #       Stages:
# #         - Name: Source
# #           Actions:
# #             - Name: CodeConnections
# #               ActionTypeId:
# #                 Category: Source
# #                 Owner: AWS
# #                 Provider: CodeStarSourceConnection
# #                 Version: '1'
# #               Configuration:
# #                 ConnectionArn: !Ref ConnectionArn
# #                 FullRepositoryId: !Ref FullRepositoryId
# #                 BranchName: !Ref BranchName
# #               OutputArtifacts:
# #                 - Name: SourceOutput
# #               RunOrder: 1
# #           OnFailure:
# #             Result: RETRY
# #         - Name: Deploy
# #           Actions:
# #             - Name: Terraform
# #               ActionTypeId:
# #                 Category: Compute
# #                 Owner: AWS
# #                 Provider: Commands
# #                 Version: '1'
# #               Commands:
# #                 - export release=AmazonLinux
# #                 - dnf install -y dnf-plugins-core
# #                 - dnf config-manager --add-repo https://rpm.releases.hashicorp.com/$release/hashicorp.repo
# #                 - dnf install -y terraform
# #                 - terraform init
# #                 - terraform fmt -check
# #                 - terraform plan -input=false
# #                 - terraform apply -auto-approve -input=false
# #               InputArtifacts:
# #                 - Name: SourceOutput
# #               RunOrder: 1
# #   CodePipelineArtifactsBucket:
# #     Type: AWS::S3::Bucket
# #     Properties:
# #       BucketEncryption:
# #         ServerSideEncryptionConfiguration:
# #           - ServerSideEncryptionByDefault:
# #               SSEAlgorithm: aws:kms
# #       PublicAccessBlockConfiguration:
# #         BlockPublicAcls: true
# #         BlockPublicPolicy: true
# #         IgnorePublicAcls: true
# #         RestrictPublicBuckets: true
# #     UpdateReplacePolicy: !Ref RetentionPolicy
# #     DeletionPolicy: !Ref RetentionPolicy
# #   CodePipelineArtifactsBucketPolicy:
# #     Type: AWS::S3::BucketPolicy
# #     Properties:
# #       Bucket: !Ref CodePipelineArtifactsBucket
# #       PolicyDocument:
# #         Statement:
# #           - Action: s3:*
# #             Condition:
# #               Bool:
# #                 aws:SecureTransport: 'false'
# #             Effect: Deny
# #             Principal:
# #               AWS: '*'
# #             Resource:
# #               - !GetAtt CodePipelineArtifactsBucket.Arn
# #               - !Join
# #                 - '/'
# #                 - - !GetAtt CodePipelineArtifactsBucket.Arn
# #                   - '*'
# #         Version: '2012-10-17'
# #   CodePipelineRole:
# #     Condition: CreatePipelineRole
# #     Type: AWS::IAM::Role
# #     Properties:
# #       AssumeRolePolicyDocument:
# #         Statement:
# #           - Action: sts:AssumeRole
# #             Condition:
# #               StringEquals:
# #                 aws:SourceAccount: !Ref AWS::AccountId
# #             Effect: Allow
# #             Principal:
# #               Service: codepipeline.amazonaws.com
# #         Version: '2012-10-17'
# #   CodePipelineRoleDefaultPolicy:
# #     Condition: CreatePipelineRole
# #     Type: AWS::IAM::Policy
# #     Properties:
# #       PolicyDocument:
# #         Statement:
# #           - Action:
# #               - s3:PutObject
# #               - s3:GetObject
# #               - s3:GetObjectVersion
# #               - s3:GetBucketVersioning
# #               - s3:GetBucketAcl
# #               - s3:GetBucketLocation
# #             Condition:
# #               StringEquals:
# #                 aws:ResourceAccount: !Ref AWS::AccountId
# #             Effect: Allow
# #             Resource:
# #               - !GetAtt CodePipelineArtifactsBucket.Arn
# #               - !Join
# #                 - '/'
# #                 - - !GetAtt CodePipelineArtifactsBucket.Arn
# #                   - '*'
# #           - Action:
# #               - codestar-connections:UseConnection
# #             Effect: Allow
# #             Resource: !Ref ConnectionArn
# #           - Action:
# #               - logs:CreateLogGroup
# #               - logs:CreateLogStream
# #               - logs:PutLogEvents
# #             Effect: Allow
# #             Resource:
# #               - !Sub
# #                 - arn:${AWS::Partition}:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/codepipeline/${pipelineName}
# #                 - pipelineName: !Ref CodePipelineName
# #               - !Sub
# #                 - arn:${AWS::Partition}:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/codepipeline/${pipelineName}:log-stream:*
# #                 - pipelineName: !Ref CodePipelineName
# #         Version: '2012-10-17'
# #       PolicyName: CodePipelineRoleDefaultPolicy
# #       Roles:
# #         - !Ref CodePipelineRole
