############################################
# ACM Certificate
############################################

resource "aws_acm_certificate" "this" {
  domain_name       = var.host_header
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.tags, { Name = "${var.project}-${var.env}-cert" })
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn

  timeouts {
    create = "45m"
  }
}

############################################
# Secrets Manager — OIDC client secret
# Run ONCE before terraform apply:
# aws secretsmanager create-secret \
#   --name "n8n/prod/entra-oidc-client-secret" \
#   --secret-string "your-client-secret" \
#   --region us-east-1
############################################

data "aws_secretsmanager_secret" "oidc" {
  name = "${var.project}/${var.env}/entra-oidc-client-secret"
}

data "aws_secretsmanager_secret_version" "oidc" {
  secret_id = data.aws_secretsmanager_secret.oidc.id
}

############################################
# ALB egress to Azure — required for OIDC
############################################

resource "aws_vpc_security_group_egress_rule" "alb_to_azure_oidc" {
  security_group_id = aws_security_group.alb.id
  description       = "ALB to Azure OIDC endpoints for token verification"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
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
# OIDC auth + forward rule
############################################

resource "aws_lb_listener_rule" "oidc_forward" {
  count        = var.host_header != "" ? 1 : 0
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  condition {
    host_header {
      values = [var.host_header]
    }
  }

  # Step 1: authenticate against Entra ID
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

  # Step 2: forward to single target group — use target_group_arn NOT forward block
  # forward block requires 2+ target groups, target_group_arn is correct for single TG
  action {
    type             = "forward"
    order            = 2
    target_group_arn = aws_lb_target_group.service.arn
  }
}
