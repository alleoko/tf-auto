###############################################################################
# outputs.tf
###############################################################################

output "ecr_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.main.repository_url
}

output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.main.name
}

output "pipeline_name" {
  description = "CodePipeline name"
  value       = aws_codepipeline.main.name
}

output "codestar_connection_arn" {
  description = "CodeStar connection ARN - must be activated in AWS Console"
  value       = aws_codestarconnections_connection.main.arn
}
