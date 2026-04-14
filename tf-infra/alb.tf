###############################################################################
# alb.tf  –  Public ALB (webapp + magi-api gateway) and Internal ALB (downstream APIs)
#
# Architecture (No NAT):
#   Browser → Public ALB → webapp (port 80) or magi-api (port 3000 /v1/*)
#   magi-api (api_tasks SG) → Internal ALB → downstream services
###############################################################################

# ── Public ALB for webapp and magi-api gateway ────────────────────────────────

resource "aws_lb" "webapp" {
  name               = "${var.app_name}-webapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_alb.id]
  subnets            = module.vpc.public_subnets
  tags               = local.common_tags

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_lb_target_group" "webapp" {
  name        = "${var.app_name}-webapp-tg"
  port        = var.webapp_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = local.common_tags
}

# magi-api gateway is publicly accessible — browsers call it directly via /v1/*
resource "aws_lb_target_group" "magi_api" {
  name        = "${var.app_name}-magi-api-tg"
  port        = var.api_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, { Service = "magi-api" })
}

# Public ALB listener — route /v1/* to magi-api, everything else to webapp
resource "aws_lb_listener" "webapp" {
  load_balancer_arn = aws_lb.webapp.arn
  port              = 80
  protocol          = "HTTP"

  # Default action: serve the webapp SPA
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp.arn
  }
}

# Higher-priority rule: /v1/* → magi-api gateway
resource "aws_lb_listener_rule" "public_magi_api" {
  listener_arn = aws_lb_listener.webapp.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.magi_api.arn
  }

  condition {
    path_pattern {
      values = ["/v1/*"]
    }
  }
}

# ── Internal ALB for downstream API services (service-to-service only) ────────
#
# Accessible from: webapp_tasks SG and api_tasks SG (magi-api proxies through here)

resource "aws_lb" "api" {
  name               = "${var.app_name}-api-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_alb.id]
  subnets            = module.vpc.private_subnets
  tags               = local.common_tags
}

resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = "{\"message\": \"Not found\"}"
      status_code  = "404"
    }
  }
}

# Downstream services — magi-api is NOT here (it's on the public ALB)
locals {
  api_services = ["users", "patient", "facility", "guarantor", "inventory", "reports"]
}

resource "aws_lb_target_group" "api" {
  for_each    = toset(local.api_services)
  name        = "${var.app_name}-${each.key}-tg"
  port        = var.api_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, { Service = each.key })
}

# ── Internal ALB listener rules — path-based routing to downstream services ───

resource "aws_lb_listener_rule" "users" {
  listener_arn = aws_lb_listener.api.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api["users"].arn
  }

  condition {
    path_pattern {
      values = ["/v1/user*", "/v1/users*", "/v1/role*", "/v1/permission*", "/v1/doctor-fee*"]
    }
  }
}

resource "aws_lb_listener_rule" "patient_1" {
  listener_arn = aws_lb_listener.api.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api["patient"].arn
  }

  condition {
    path_pattern {
      values = ["/v1/patient", "/v1/patient/*", "/v1/patients", "/v1/case", "/v1/case/*"]
    }
  }
}

resource "aws_lb_listener_rule" "patient_2" {
  listener_arn = aws_lb_listener.api.arn
  priority     = 21

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api["patient"].arn
  }

  condition {
    path_pattern {
      values = ["/v1/cases", "/v1/vital", "/v1/vital/*", "/v1/vitals", "/v1/charge"]
    }
  }
}

resource "aws_lb_listener_rule" "patient_3" {
  listener_arn = aws_lb_listener.api.arn
  priority     = 22

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api["patient"].arn
  }

  condition {
    path_pattern {
      values = ["/v1/charge/*", "/v1/charges", "/v1/patient-diet", "/v1/patient-diet/*", "/v1/patient-diets"]
    }
  }
}

resource "aws_lb_listener_rule" "patient_4" {
  listener_arn = aws_lb_listener.api.arn
  priority     = 23

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api["patient"].arn
  }

  condition {
    path_pattern {
      values = ["/v1/service-type", "/v1/service-type/*", "/v1/service-types", "/v1/informant", "/v1/informant/*"]
    }
  }
}

resource "aws_lb_listener_rule" "patient_5" {
  listener_arn = aws_lb_listener.api.arn
  priority     = 24

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api["patient"].arn
  }

  condition {
    path_pattern {
      values = ["/v1/billing", "/v1/billing/*", "/v1/dashboard", "/v1/dashboard/*"]
    }
  }
}

resource "aws_lb_listener_rule" "facility" {
  listener_arn = aws_lb_listener.api.arn
  priority     = 35

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api["facility"].arn
  }

  condition {
    path_pattern {
      values = ["/v1/facility*", "/v1/facilities*", "/v1/department*", "/v1/ward*", "/v1/room*", "/v1/bed*", "/v1/transfer-order*"]
    }
  }
}

resource "aws_lb_listener_rule" "guarantor" {
  listener_arn = aws_lb_listener.api.arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api["guarantor"].arn
  }

  condition {
    path_pattern {
      values = ["/v1/guarantor*", "/v1/guarantors*", "/v1/hmo*", "/v1/patient-hmo*", "/v1/patient-guarantor*"]
    }
  }
}

resource "aws_lb_listener_rule" "inventory" {
  listener_arn = aws_lb_listener.api.arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api["inventory"].arn
  }

  condition {
    path_pattern {
      values = ["/v1/item*", "/v1/items*", "/v1/item-category*", "/v1/order*", "/v1/orders*", "/v1/requisition*", "/v1/inventory*"]
    }
  }
}

resource "aws_lb_listener_rule" "reports" {
  listener_arn = aws_lb_listener.api.arn
  priority     = 60

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api["reports"].arn
  }

  condition {
    path_pattern {
      values = ["/v1/invoice*", "/v1/payment*", "/v1/payments*"]
    }
  }
}
