locals {
  tags = {
    Project   = var.project
    Env       = var.env
    ManagedBy = "terraform"
  }
}

resource "aws_lb" "this" {
  name               = "${var.project}-${var.env}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for s in aws_subnet.public : s.id]

  enable_deletion_protection = false

  access_logs {
    bucket  = var.alb_logs_bucket
    prefix  = var.alb_logs_prefix
    enabled = true
  }

  tags = merge(local.tags, { Name = "${var.project}-${var.env}-alb" })

  depends_on = [aws_s3_bucket_policy.alb_logs]
}

resource "aws_lb_target_group" "service" {
  name        = "${var.project}-${var.env}-service-tg"
  vpc_id      = aws_vpc.this.id
  target_type = "ip"
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

  stickiness {
    type            = "lb_cookie"
    cookie_duration = var.oidc_session_timeout
    enabled         = true
  }

  deregistration_delay = 30

  tags = merge(local.tags, { Name = "${var.project}-${var.env}-service-tg" })
}

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

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.service_cert.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
}

resource "aws_lb_listener_rule" "oidc_forward" {
  count        = var.host_header != "" ? 1 : 0
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  condition {
    host_header {
      values = [var.host_header]
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
      client_secret              = data.aws_secretsmanager_secret_version.oidc.secret_string
      scope                      = "openid email profile"
      on_unauthenticated_request = "authenticate"
      session_cookie_name        = "AWSELBAuthSessionCookie"
      session_timeout            = var.oidc_session_timeout
    }
  }

  action {
    type             = "forward"
    order            = 2
    target_group_arn = aws_lb_target_group.service.arn
  }
}

resource "aws_acm_certificate" "service_cert" {
  domain_name       = var.host_header
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.tags, { Name = "${var.project}-${var.env}-cert" })
}

resource "aws_acm_certificate_validation" "service_cert" {
  certificate_arn = aws_acm_certificate.service_cert.arn

  timeouts {
    create = "45m"
  }
}

data "aws_secretsmanager_secret" "oidc" {
  name = "${var.project}/${var.env}/entra-oidc-client-secret"
}

data "aws_secretsmanager_secret_version" "oidc" {
  secret_id = data.aws_secretsmanager_secret.oidc.id
}

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

resource "aws_cloudwatch_log_group" "vpc_flow" {
  name              = "/aws/vpc/${var.project}-${var.env}/flowlogs"
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = local.tags
}

data "aws_iam_policy_document" "flowlogs_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flowlogs" {
  name               = "${var.project}-${var.env}-vpc-flowlogs-role"
  assume_role_policy = data.aws_iam_policy_document.flowlogs_assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "flowlogs_write" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["${aws_cloudwatch_log_group.vpc_flow.arn}:*"]
  }
}

resource "aws_iam_role_policy" "flowlogs_write" {
  name   = "${var.project}-${var.env}-vpc-flowlogs-write"
  role   = aws_iam_role.flowlogs.id
  policy = data.aws_iam_policy_document.flowlogs_write.json
}

resource "aws_flow_log" "this" {
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow.arn
  iam_role_arn         = aws_iam_role.flowlogs.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this.id
  tags                 = local.tags
}
