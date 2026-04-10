###############################################################################
# security_groups.tf
###############################################################################

# Public ALB
resource "aws_security_group" "public_alb" {
  name        = "${var.app_name}-public-alb-sg"
  description = "Public ALB - allow HTTP and HTTPS from internet"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.app_name}-public-alb-sg" })
}

# Webapp ECS tasks
resource "aws_security_group" "webapp_tasks" {
  name        = "${var.app_name}-webapp-tasks-sg"
  description = "Webapp ECS tasks - allow from public ALB only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = var.webapp_port
    to_port         = var.webapp_port
    protocol        = "tcp"
    security_groups = [aws_security_group.public_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.app_name}-webapp-tasks-sg" })
}

# Internal ALB
resource "aws_security_group" "internal_alb" {
  name        = "${var.app_name}-internal-alb-sg"
  description = "Internal ALB - allow from webapp tasks only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.webapp_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.app_name}-internal-alb-sg" })
}

# API ECS tasks
resource "aws_security_group" "api_tasks" {
  name        = "${var.app_name}-api-tasks-sg"
  description = "API ECS tasks - allow from internal ALB only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = var.api_port
    to_port         = var.api_port
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.app_name}-api-tasks-sg" })
}

# RDS
resource "aws_security_group" "rds" {
  name        = "${var.app_name}-rds-sg"
  description = "RDS - allow PostgreSQL from API tasks only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.api_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.app_name}-rds-sg" })
}
