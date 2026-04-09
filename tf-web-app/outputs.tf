output "ecr_url"      { value = aws_ecr_repository.main.repository_url }
output "service_name" { value = aws_ecs_service.main.name }
output "pipeline_name" { value = aws_codepipeline.main.name }
output "codestar_connection_arn" { value = aws_codestarconnections_connection.main.arn }
