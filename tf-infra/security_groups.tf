# Webapp tasks SG
resource "aws_security_group" "webapp_tasks" {
  name        = "${var.app_name}-webapp-tasks-sg"
  description = "Webapp ECS tasks   allow HTTP from internet"
  vpc_id      = module.vpc.vpc_id

  ingress { 
    from_port   = var.webapp_port 
    to_port     = var.webapp_port 
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"]
    }
  egress  { 
    from_port   = 0 
    to_port     = 0 
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  tags = merge(local.common_tags, { Name = "${var.app_name}-webapp-tasks-sg" })
}

# API tasks SG
resource "aws_security_group" "api_tasks" {
  name        = "${var.app_name}-api-tasks-sg"
  description = "API ECS tasks   allow from webapp tasks"
  vpc_id      = module.vpc.vpc_id

  ingress { 
    from_port       = var.api_port 
    to_port         = var.api_port 
    protocol        = "tcp" 
    security_groups = [aws_security_group.webapp_tasks.id] 
    }
  egress  { 
    from_port   = 0
    to_port     = 0 
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  tags = merge(local.common_tags, { Name = "${var.app_name}-api-tasks-sg" })
}

# RDS SG
resource "aws_security_group" "rds" {
  name        = "${var.app_name}-rds-sg"
  description = "RDS   allow Postgres from API tasks"
  vpc_id      = module.vpc.vpc_id

  ingress { 
    from_port       = 5432 
    to_port         = 5432 
    protocol        = "tcp" 
    security_groups = [aws_security_group.api_tasks.id] 
    }
  egress  { 
    from_port   = 0    
    to_port     = 0    
    protocol    = "-1"  
    cidr_blocks = ["0.0.0.0/0"] 
    }

  tags = merge(local.common_tags, { Name = "${var.app_name}-rds-sg" })
}
