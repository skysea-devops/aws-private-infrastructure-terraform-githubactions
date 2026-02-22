# ============================================================================
# CLOUDWATCH DASHBOARD
# ============================================================================

resource "aws_cloudwatch_dashboard" "main" {
  count = var.enable_dashboard ? 1 : 0
  
  dashboard_name = "${var.project}-${var.env}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      # Row 1: ALB Metrics
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 0
        y      = 0
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { label = "Avg Response Time", stat = "Average" }],
            ["...", { label = "Max Response Time", stat = "Maximum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ALB Response Time"
          period  = 300
          yAxis = {
            left = {
              label = "Seconds"
              min   = 0
            }
          }
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 12
        y      = 0
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", { stat = "Sum", label = "Total Requests" }],
            [".", "HTTPCode_Target_2XX_Count", { stat = "Sum", label = "2XX Success" }],
            [".", "HTTPCode_Target_4XX_Count", { stat = "Sum", label = "4XX Client Error" }],
            [".", "HTTPCode_Target_5XX_Count", { stat = "Sum", label = "5XX Server Error" }]
          ]
          view    = "timeSeries"
          stacked = true
          region  = var.aws_region
          title   = "ALB Request Count by Status"
          period  = 300
          yAxis = {
            left = {
              label = "Count"
              min   = 0
            }
          }
        }
      },
      
      # Row 2: EC2 Metrics
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 0
        y      = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", label = "CPU Average" }],
            ["...", { stat = "Maximum", label = "CPU Max" }]
          ]
          view   = "timeSeries"
          stacked = false
          region = var.aws_region
          title  = "EC2 CPU Utilization"
          period = 300
          yAxis = {
            left = {
              label = "Percent"
              min   = 0
              max   = 100
            }
          }
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 12
        y      = 6
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", { stat = "Sum", label = "Network In" }],
            [".", "NetworkOut", { stat = "Sum", label = "Network Out" }]
          ]
          view   = "timeSeries"
          stacked = false
          region = var.aws_region
          title  = "EC2 Network Traffic"
          period = 300
          yAxis = {
            left = {
              label = "Bytes"
              min   = 0
            }
          }
        }
      },
      
      # Row 3: RDS Metrics
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 0
        y      = 12
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { stat = "Average", label = "CPU Average" }],
            ["...", { stat = "Maximum", label = "CPU Max" }]
          ]
          view   = "timeSeries"
          stacked = false
          region = var.aws_region
          title  = "RDS CPU Utilization"
          period = 300
          yAxis = {
            left = {
              label = "Percent"
              min   = 0
              max   = 100
            }
          }
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 12
        y      = 12
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", { stat = "Average", label = "Connections" }]
          ]
          view   = "timeSeries"
          stacked = false
          region = var.aws_region
          title  = "RDS Database Connections"
          period = 300
          yAxis = {
            left = {
              label = "Count"
              min   = 0
            }
          }
        }
      },
      
      # Row 4: RDS Storage
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 0
        y      = 18
        properties = {
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", { stat = "Average", label = "Free Storage" }]
          ]
          view   = "timeSeries"
          stacked = false
          region = var.aws_region
          title  = "RDS Free Storage Space"
          period = 300
          yAxis = {
            left = {
              label = "Bytes"
              min   = 0
            }
          }
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 12
        y      = 18
        properties = {
          metrics = [
            ["AWS/RDS", "FreeableMemory", { stat = "Average", label = "Freeable Memory" }]
          ]
          view   = "timeSeries"
          stacked = false
          region = var.aws_region
          title  = "RDS Freeable Memory"
          period = 300
          yAxis = {
            left = {
              label = "Bytes"
              min   = 0
            }
          }
        }
      }
    ]
  })
}
