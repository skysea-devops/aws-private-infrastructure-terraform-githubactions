# ============================================================================
# MONITORING MODULE - VARIABLES
# ============================================================================
# File: monitoring/variables.tf

variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = ""
}

variable "enable_guardduty" {
  description = "Enable GuardDuty threat detection"
  type        = bool
  default     = true
}

variable "enable_dashboard" {
  description = "Create CloudWatch dashboard"
  type        = bool
  default     = true
}

# Resource references from parent
variable "alb_arn_suffix" {
  description = "ALB ARN suffix"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix"
  type        = string
}

variable "ec2_instance_id" {
  description = "EC2 instance ID"
  type        = string
}

variable "rds_instance_id" {
  description = "RDS instance ID"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
