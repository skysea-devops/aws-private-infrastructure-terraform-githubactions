############################################
# ALB + Target Group + Listeners
############################################

resource "aws_lb" "this" {
  name               = "${var.project}-${var.env}-alb"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.alb.id]
  subnets         = [for s in aws_subnet.public : s.id]

  enable_deletion_protection = false

  tags = merge(local.tags, { Name = "${var.project}-${var.env}-alb" })
}

resource "aws_lb_target_group" "n8n" {
  name        = "${var.project}-${var.env}-n8n-tg"
  vpc_id      = aws_vpc.this.id
  target_type = "ip"     # EC2 instance ile attach edeceksen "instance"
  port        = var.n8n_app_port
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

  tags = merge(local.tags, { Name = "${var.project}-${var.env}-n8n-tg" })
}

# Opsiyonel: 80 -> 443 redirect
resource "aws_lb_listener" "http" {
  count             = var.enable_http_redirect ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

}


# Host-based rule (isteğe bağlı)
resource "aws_lb_listener_rule" "host_forward" {
  count        = var.host_header != "" ? 1 : 0
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.n8n.arn
  }

  condition {
    host_header {
      values = [var.host_header]
    }
  }
}

############################################
# VPC Flow Logs -> CloudWatch Logs
############################################

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
