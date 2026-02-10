############################################
# alb.tf — ALB + Target Group + Listeners
############################################

resource "aws_lb" "this" {
  name               = "${var.project}-${var.env}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [local.p2.alb_sg_id]
  subnets            = local.p2.public_subnet_ids

  enable_deletion_protection = true

  access_logs {
    bucket  = var.alb_logs_bucket
    prefix  = var.alb_logs_prefix
    enabled = true
  }

  tags = merge(local.tags, { Name = "${var.project}-${var.env}-alb" })
}

############################################
# Target Group
############################################

resource "aws_lb_target_group" "this" {
  name        = "${var.project}-${var.env}-tg"
  vpc_id      = local.p2.vpc_id
  target_type = "instance"
  port        = var.service_app_port
  protocol    = "HTTP"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = var.health_check_path
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  stickiness {
    type            = "lb_cookie"
    cookie_duration = var.oidc_session_timeout
    enabled         = true
  }

  tags = merge(local.tags, { Name = "${var.project}-${var.env}-tg" })
}

############################################
# HTTP → HTTPS redirect
############################################

resource "aws_lb_listener" "http" {
  count             = var.enable_http_redirect ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

############################################
# HTTPS listener — default 403
############################################

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.this.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
}

############################################
# Listener rule — OIDC + forward
############################################

resource "aws_lb_listener_rule" "oidc_forward" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  condition {
    host_header {
      values = [var.domain_name]
    }
  }

  action {
    type  = "authenticate-oidc"
    order = 1

    authenticate_oidc {
      issuer                     = "https://login.microsoftonline.com/${var.entra_tenant_id}/v2.0"
      authorization_endpoint     = "https://login.microsoftonline.com/${var.entra_tenant_id}/oauth2/v2.0/authorize"
      token_endpoint             = "https://login.microsoftonline.com/${var.entra_tenant_id}/oauth2/v2.0/token"
      user_info_endpoint         = "https://graph.microsoft.com/oidc/userinfo"
      client_id                  = var.entra_client_id
      client_secret              = aws_secretsmanager_secret_version.oidc.secret_string
      scope                      = "openid email profile"
      on_unauthenticated_request = "authenticate"
      session_cookie_name        = "AWSELBAuthSessionCookie"
      session_timeout            = var.oidc_session_timeout
    }
  }

  action {
    type             = "forward"
    order            = 2
    target_group_arn = aws_lb_target_group.this.arn
  }
}

############################################
# S3 bucket policy — ALB access logs
############################################

data "aws_elb_service_account" "main" {}

data "aws_s3_bucket" "alb_logs" {
  bucket = var.alb_logs_bucket
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = data.aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowALBLogDelivery"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root" }
        Action    = "s3:PutObject"
        Resource  = "${data.aws_s3_bucket.alb_logs.arn}/${var.alb_logs_prefix}/AWSLogs/*"
      },
      {
        Sid       = "AllowLogDeliveryService"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${data.aws_s3_bucket.alb_logs.arn}/${var.alb_logs_prefix}/AWSLogs/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      },
      {
        Sid       = "AllowGetBucketAcl"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = data.aws_s3_bucket.alb_logs.arn
      }
    ]
  })
}
