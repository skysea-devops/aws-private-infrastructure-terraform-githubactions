# ============================================================================
# ALB CLOUDWATCH ALARMS
# ============================================================================

# Alarm 1: ALB 5xx Errors Elevated
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project}-${var.env}-alb-5xx-elevated"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300  # 5 minutes
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB returning 5xx errors - application issue"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
  }
  
  tags = local.tags
}

# Alarm 2: Target Unhealthy
resource "aws_cloudwatch_metric_alarm" "target_unhealthy" {
  alarm_name          = "${var.project}-${var.env}-target-unhealthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "No healthy targets available - service down"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "breaching"
  
  dimensions = {
    TargetGroup  = aws_lb_target_group.service.arn_suffix
    LoadBalancer = aws_lb.this.arn_suffix
  }
  
  tags = local.tags
}

# Alarm 3: Response Time High
resource "aws_cloudwatch_metric_alarm" "alb_response_time" {
  alarm_name          = "${var.project}-${var.env}-alb-response-slow"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 2.0  # 2 seconds
  alarm_description   = "ALB response time > 2s - performance issue"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
  }
  
  tags = local.tags
}
