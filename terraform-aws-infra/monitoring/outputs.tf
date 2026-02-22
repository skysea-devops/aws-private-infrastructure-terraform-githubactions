# ============================================================================
# MONITORING MODULE - OUTPUTS
# ============================================================================
# File: monitoring/outputs.tf

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "SNS topic name"
  value       = aws_sns_topic.alerts.name
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = var.enable_guardduty ? aws_guardduty_detector.main.id : null
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = var.enable_dashboard ? aws_cloudwatch_dashboard.main[0].dashboard_name : null
}

output "alarm_arns" {
  description = "Map of alarm ARNs"
  value = {
    alb_5xx            = aws_cloudwatch_metric_alarm.alb_5xx.arn
    target_unhealthy   = aws_cloudwatch_metric_alarm.target_unhealthy.arn
    alb_response_time  = aws_cloudwatch_metric_alarm.alb_response_time.arn
    ec2_cpu_high       = aws_cloudwatch_metric_alarm.ec2_cpu_high.arn
    ec2_status_check   = aws_cloudwatch_metric_alarm.ec2_status_check.arn
    rds_cpu_high       = aws_cloudwatch_metric_alarm.rds_cpu_high.arn
    rds_storage_low    = aws_cloudwatch_metric_alarm.rds_storage_low.arn
    rds_connections    = aws_cloudwatch_metric_alarm.rds_connections_high.arn
    rds_memory_low     = aws_cloudwatch_metric_alarm.rds_memory_low.arn
  }
}
