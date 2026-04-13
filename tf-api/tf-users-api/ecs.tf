###############################################################################
# ecs.tf  –  ECS task definition, service, autoscaling for users
###############################################################################

resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/magi-app-stg-users"
  retention_in_days = 14
  tags              = local.common_tags
}

resource "aws_ecs_task_definition" "main" {
  family                   = "magi-app-stg-users"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = data.terraform_remote_state.infra.outputs.ecs_task_execution_role_arn
  task_role_arn            = data.terraform_remote_state.infra.outputs.ecs_task_role_arn

  container_definitions = jsonencode([{
    name      = "magi-app-stg-users"
    image     = "${aws_ecr_repository.main.repository_url}:latest"
    essential = true

    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/magi-app-stg-users"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    environment = [
      { name = "NODE_ENV",  value = var.environment },
      { name = "PORT",      value = "3000" },
      { name = "DB_NAME",   value = var.db_name },
      { name = "DB_HOST",   value = data.terraform_remote_state.infra.outputs.rds_endpoint },
      { name = "DB_PORT",   value = tostring(data.terraform_remote_state.infra.outputs.rds_port) },
      { name = "DB_USER",   value = var.db_username },
      { name = "CORS_ORIGIN", value = "http://${data.terraform_remote_state.infra.outputs.webapp_alb_dns}" }
    ]

    secrets = [
      { name = "DB_PASSWORD",    valueFrom = data.terraform_remote_state.infra.outputs.ssm_db_password_arn },
      { name = "JWT_TOKEN",      valueFrom = data.terraform_remote_state.infra.outputs.ssm_jwt_token_arn },
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
  name            = "magi-app-stg-users-service"
  cluster         = data.terraform_remote_state.infra.outputs.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

 # network_configuration {
 #   subnets          = data.terraform_remote_state.infra.outputs.private_subnet_ids
 #   security_groups  = [data.terraform_remote_state.infra.outputs.sg_api_tasks_id]
 #   assign_public_ip = false
 # }
  network_configuration {
  subnets          = data.terraform_remote_state.infra.outputs.public_subnet_ids
  security_groups  = [data.terraform_remote_state.infra.outputs.sg_api_tasks_id]
  assign_public_ip = true   # tasks get public IP to reach ECR/CloudWatch
  # 
} 

#Able to do
  load_balancer {
    target_group_arn = data.terraform_remote_state.infra.outputs.api_target_group_arns["users"]
    container_name   = "magi-app-stg-users"
    container_port   = 3000
  }

  lifecycle { ignore_changes = [task_definition, desired_count] }
  tags = local.common_tags
}

resource "aws_appautoscaling_target" "main" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${data.terraform_remote_state.infra.outputs.ecs_cluster_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "main" {
  name               = "magi-app-stg-users-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
