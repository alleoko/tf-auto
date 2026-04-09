resource "aws_ssm_parameter" "db_password" {
  name   = "/${var.app_name}/${var.environment}/db_password"
  type   = "SecureString"
  value  = var.db_password
  key_id = "alias/aws/ssm"
  tags   = local.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "jwt_token" {
  name   = "/${var.app_name}/${var.environment}/jwt_token"
  type   = "SecureString"
  value  = var.jwt_token
  key_id = "alias/aws/ssm"
  tags   = local.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "service_secret" {
  name   = "/${var.app_name}/${var.environment}/service_secret"
  type   = "SecureString"
  value  = var.service_secret
  key_id = "alias/aws/ssm"
  tags   = local.common_tags
  lifecycle { ignore_changes = [value] }
}
