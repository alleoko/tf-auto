resource "aws_codestarconnections_connection" "main" {
  name          = "${var.app_name}-webapp-github"
  provider_type = "GitHub"
  tags          = local.common_tags
}

resource "aws_codebuild_project" "main" {
  name          = "${var.app_name}-webapp-build"
  build_timeout = 20
  service_role  = data.terraform_remote_state.infra.outputs.codebuild_role_arn

  artifacts { type = "CODEPIPELINE" }
  cache { 
    type = "LOCAL" 
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"] 
    }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable { 
      name = "AWS_DEFAULT_REGION" 
      value = var.aws_region 
      }
    environment_variable { 
      name = "AWS_ACCOUNT_ID"     
      value = data.aws_caller_identity.current.account_id 
      }
    environment_variable { 
      name = "ECR_REPO_URI"       
      value = aws_ecr_repository.main.repository_url 
      }
    environment_variable { 
      name = "CONTAINER_NAME"     
      value = "${var.app_name}-webapp" 
      }
  }

  source { 
    type = "CODEPIPELINE" 
    buildspec = "buildspec.yml" 
    }
  logs_config { 
    cloudwatch_logs { 
      group_name = "/codebuild/${var.app_name}-webapp" 
      stream_name = "build" 
      } 
      }
  tags = local.common_tags
}

resource "aws_codepipeline" "main" {
  name     = "${var.app_name}-webapp-pipeline"
  role_arn = data.terraform_remote_state.infra.outputs.codepipeline_role_arn

  artifact_store {
    location = data.terraform_remote_state.infra.outputs.artifacts_bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.main.arn
        FullRepositoryId     = var.github_repo
        BranchName           = var.github_branch
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      configuration    = { ProjectName = aws_codebuild_project.main.name }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]
      configuration = {
        ClusterName = data.terraform_remote_state.infra.outputs.ecs_cluster_name
        ServiceName = aws_ecs_service.main.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  tags = local.common_tags
}
