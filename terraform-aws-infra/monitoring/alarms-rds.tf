# ============================================================================
# RDS CLOUDWATCH ALARMS
# ============================================================================

# Alarm 1: CPU High
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project}-${var.env}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300  # 5 minutes
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU > 80% for 10 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }
  
  tags = local.tags
}

# Alarm 2: Free Storage Low
resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "${var.project}-${var.env}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648  # 2 GB in bytes
  alarm_description   = "RDS free storage < 2GB"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }
  
  tags = local.tags
}

# Alarm 3: Database Connections High
resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "${var.project}-${var.env}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  alarm_description   = "RDS connections > 50"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }
  
  tags = local.tags
}

# Alarm 4: Freeable Memory Low
resource "aws_cloudwatch_metric_alarm" "rds_memory_low" {
  alarm_name          = "${var.project}-${var.env}-rds-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 268435456  # 256 MB in bytes
  alarm_description   = "RDS freeable memory < 256MB"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }
  
  tags = local.tags
}
