###############################################################################
# ecs.tf  –  ECS task definition, service, autoscaling for webapp
#
# NOTE on VITE_MAGI_API_URL:
#   Vite bakes environment variables into the JS bundle at BUILD TIME.
#   Setting them as ECS runtime environment variables has zero effect on the
#   already-compiled static assets served by Nginx.
#   The API URL is injected during CodeBuild via --build-arg VITE_MAGI_API_URL.
#   See tf-web-app/codepipeline.tf for where the value is set.
###############################################################################

resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/magi-app-stg-webapp"
  retention_in_days = 14
  tags              = local.common_tags
}

resource "aws_ecs_task_definition" "main" {
  family                   = "magi-app-stg-webapp"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = data.terraform_remote_state.infra.outputs.ecs_task_execution_role_arn
  task_role_arn            = data.terraform_remote_state.infra.outputs.ecs_task_role_arn

  container_definitions = jsonencode([{
    name      = "magi-app-stg-webapp"
    image     = "${aws_ecr_repository.main.repository_url}:latest"
    essential = true

    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/magi-app-stg-webapp"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    environment = [
      { name = "NODE_ENV", value = var.environment },
      { name = "PORT",     value = "80" },
    ]

    secrets = [
      { name = "JWT_TOKEN",      valueFrom = data.terraform_remote_state.infra.outputs.ssm_jwt_token_arn },
      { name = "SERVICE_SECRET", valueFrom = data.terraform_remote_state.infra.outputs.ssm_service_secret_arn },
    ]

    healthCheck = {
      command     = ["CMD-SHELL", "wget -qO- http://localhost:80/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = local.common_tags
}

resource "aws_ecs_service" "main" {
  name            = "magi-app-stg-webapp-service"
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

  # No NAT: public subnet + public IP for ECR pulls and CloudWatch logs.
  network_configuration {
    subnets          = data.terraform_remote_state.infra.outputs.public_subnet_ids
    security_groups  = [data.terraform_remote_state.infra.outputs.sg_webapp_tasks_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = data.terraform_remote_state.infra.outputs.webapp_target_group_arn
    container_name   = "magi-app-stg-webapp"
    container_port   = 80
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
  name               = "magi-app-stg-webapp-cpu-scaling"
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
