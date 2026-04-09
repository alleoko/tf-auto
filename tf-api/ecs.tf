resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.app_name}-webapp"
  retention_in_days = 14
  tags              = local.common_tags
}

resource "aws_ecs_task_definition" "main" {
  family                   = "${var.app_name}-webapp"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = data.terraform_remote_state.infra.outputs.ecs_task_execution_role_arn
  task_role_arn            = data.terraform_remote_state.infra.outputs.ecs_task_role_arn

  container_definitions = jsonencode([{
    name      = "${var.app_name}-webapp"
    image     = "${aws_ecr_repository.main.repository_url}:latest"
    essential = true
    portMappings = [{ containerPort = 3000, protocol = "tcp" }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.app_name}-webapp"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
    environment = [
      { name = "NODE_ENV", value = var.environment },
      { name = "PORT",     value = "3000" },
      { name = "USERS_API_URL",     value = var.users_api_url },
      { name = "PATIENT_API_URL",   value = var.patient_api_url },
      { name = "FACILITY_API_URL",  value = var.facility_api_url },
      { name = "GUARANTOR_API_URL", value = var.guarantor_api_url },
      { name = "INVENTORY_API_URL", value = var.inventory_api_url },
      { name = "REPORTS_API_URL",   value = var.reports_api_url },
    ]
    secrets = [
      { name = "JWT_TOKEN", valueFrom = data.terraform_remote_state.infra.outputs.ssm_jwt_token_arn },
      { name = "SERVICE_SECRET", valueFrom = data.terraform_remote_state.infra.outputs.ssm_service_secret_arn },
    ]
    healthCheck = {
      command     = ["CMD-SHELL", "wget -qO- http://localhost:3000/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = local.common_tags
}

resource "aws_ecs_service" "main" {
  name            = "${var.app_name}-webapp-service"
  cluster         = data.terraform_remote_state.infra.outputs.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = data.terraform_remote_state.infra.outputs.private_subnet_ids
    security_groups  = [data.terraform_remote_state.infra.outputs.sg_webapp_tasks_id]
    assign_public_ip = false
  }

  lifecycle { ignore_changes = [task_definition, desired_count] }
  tags = local.common_tags
}
