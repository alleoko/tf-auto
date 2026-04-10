###############################################################################
# outputs.tf
###############################################################################

output "vpc_id"                      { value = module.vpc.vpc_id }
output "private_subnet_ids"          { value = module.vpc.private_subnets }
output "public_subnet_ids"           { value = module.vpc.public_subnets }
output "ecs_cluster_name"            { value = aws_ecs_cluster.main.name }
output "ecs_cluster_arn"             { value = aws_ecs_cluster.main.arn }
output "rds_endpoint"                { value = aws_db_instance.postgres.address }
output "rds_port"                    { value = aws_db_instance.postgres.port }
output "sg_public_alb_id"            { value = aws_security_group.public_alb.id }
output "sg_webapp_tasks_id"          { value = aws_security_group.webapp_tasks.id }
output "sg_internal_alb_id"          { value = aws_security_group.internal_alb.id }
output "sg_api_tasks_id"             { value = aws_security_group.api_tasks.id }
output "sg_rds_id"                   { value = aws_security_group.rds.id }
output "ecs_task_execution_role_arn" { value = aws_iam_role.ecs_task_execution.arn }
output "ecs_task_role_arn"           { value = aws_iam_role.ecs_task.arn }
output "codebuild_role_arn"          { value = aws_iam_role.codebuild.arn }
output "codepipeline_role_arn"       { value = aws_iam_role.codepipeline.arn }
output "artifacts_bucket"            { value = aws_s3_bucket.artifacts.bucket }
output "ssm_db_password_arn"         { value = aws_ssm_parameter.db_password.arn }
output "ssm_jwt_token_arn"           { value = aws_ssm_parameter.jwt_token.arn }
output "ssm_service_secret_arn"      { value = aws_ssm_parameter.service_secret.arn }

# ── ALB outputs (uncomment when ALB is enabled in alb.tf) ────────────────────

# output "webapp_alb_dns"            { value = aws_lb.webapp.dns_name }
# output "webapp_alb_url"            { value = "http://${aws_lb.webapp.dns_name}" }
# output "webapp_target_group_arn"   { value = aws_lb_target_group.webapp.arn }
# output "api_alb_dns"               { value = aws_lb.api.dns_name }
# output "api_alb_listener_arn"      { value = aws_lb_listener.api.arn }
# output "api_target_group_arns"     { value = { for k, v in aws_lb_target_group.api : k => v.arn } }
