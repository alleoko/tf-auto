###############################################################################
# ssm.tf  –  SSM Parameter Store secrets
###############################################################################

resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.app_name}/${var.environment}/db_password"
  description = "RDS PostgreSQL password"
  type        = "SecureString"
  value       = var.db_password
  key_id      = "alias/aws/ssm"
  tags        = local.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "jwt_token" {
  name        = "/${var.app_name}/${var.environment}/jwt_token"
  description = "JWT secret key"
  type        = "SecureString"
  value       = var.jwt_token
  key_id      = "alias/aws/ssm"
  tags        = local.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "service_secret" {
  name        = "/${var.app_name}/${var.environment}/service_secret"
  description = "Inter-service shared secret"
  type        = "SecureString"
  value       = var.service_secret
  key_id      = "alias/aws/ssm"
  tags        = local.common_tags
  lifecycle { ignore_changes = [value] }
}
