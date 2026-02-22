# ============================================================================
# EC2 CLOUDWATCH ALARMS
# ============================================================================

# Alarm 1: CPU High
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "${var.project}-${var.env}-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300  # 5 minutes
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EC2 CPU > 80% for 10 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    InstanceId = aws_instance.service.id
  }
  
  tags = local.tags
}

# Alarm 2: Status Check Failed
resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  alarm_name          = "${var.project}-${var.env}-ec2-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "EC2 status check failed - instance issue"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    InstanceId = aws_instance.service.id
  }
  
  tags = local.tags
}
