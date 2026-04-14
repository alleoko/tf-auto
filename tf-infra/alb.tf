###############################################################################
# alb.tf  –  ALB resources (commented out for now, uncomment when needed)
#
# To enable ALB:
# 1. Uncomment all resources in this file
# 2. Uncomment the load_balancer block in each service ecs.tf
# 3. Run terraform apply
###############################################################################

# ── Public ALB for webapp ─────────────────────────────────────────────────────

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

 resource "aws_lb_listener" "webapp" {
   load_balancer_arn = aws_lb.webapp.arn
   port              = 80
   protocol          = "HTTP"

   default_action {
     type             = "forward"
     target_group_arn = aws_lb_target_group.webapp.arn
   }
 }

# ── Internal ALB for all API services (path-based routing) ───────────────────

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

 locals {
   api_services = ["users", "patient", "facility", "guarantor", "inventory", "reports", "magi-api"]
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

# ── Listener rules – path-based routing ──────────────────────────────────────

 resource "aws_lb_listener_rule" "users" {
  listener_arn = aws_lb_listener.api.arn
  priority     = 30
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api["users"].arn
  }
  condition {
    path_pattern {
      values = ["/v1/user*", "/v1/users*", "/v1/role*", "/v1/permission*", "/v1/doctor-fee*" ]
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
     path_pattern { values = ["/api/facilities/*"] }
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
     path_pattern { values = ["/api/guarantors/*"] }
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
     path_pattern { values = ["/api/inventory/*"] }
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
     path_pattern { values = ["/api/reports/*"] }
   }
 }

 resource "aws_lb_listener_rule" "magi-api" {
   listener_arn = aws_lb_listener.api.arn
   priority     = 10
   action {
     type             = "forward"
     target_group_arn = aws_lb_target_group.api["magi-api"].arn
   }
   condition {
     path_pattern { values = ["/v1/*"] }
   }
 }
