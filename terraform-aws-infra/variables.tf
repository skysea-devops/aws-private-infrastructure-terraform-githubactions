# ============================================================================
# PROJECT CONFIGURATION
# ============================================================================

variable "project" {
  type        = string
  description = "Project name for resource naming and tagging"
}

variable "env" {
  type        = string
  description = "Environment (e.g., dev, staging, prod)"
}

variable "aws_region" {
  type        = string
  description = "AWS region for resource deployment"
  default     = "us-east-1"
}

# ============================================================================
# NETWORK CONFIGURATION
# ============================================================================

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "azs" {
  type        = list(string)
  description = "List of availability zones. If empty, first 2 AZs in region will be used."
  default     = []
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets"
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

# ============================================================================
# APPLICATION CONFIGURATION
# ============================================================================

variable "service_app_port" {
  type        = number
  description = "Application port for the service (e.g., app runs on 5678)"
  default     = 5678
}

variable "health_check_path" {
  type        = string
  description = "Target group health check path"
  default     = "/"
}

variable "host_header" {
  type        = string
  description = "Host header for routing (e.g., n8n.example.com). Required for OIDC listener rule."
  default     = ""
}

variable "enable_http_redirect" {
  type        = bool
  description = "Enable HTTP to HTTPS redirect (port 80 -> 443)"
  default     = true
}

# ============================================================================
# AZURE ENTRA ID (OIDC) CONFIGURATION
# ============================================================================

variable "entra_tenant_id" {
  type        = string
  description = "Azure Entra ID tenant ID for OIDC authentication"
}

variable "entra_client_id" {
  type        = string
  description = "Azure Entra ID application (client) ID"
}

variable "entra_client_secret" {
  type        = string
  description = "Azure Entra ID application client secret"
  sensitive   = true
}

variable "oidc_session_timeout" {
  type        = number
  description = "OIDC session timeout in seconds (also used for ALB stickiness)"
  default     = 3600
}

# ============================================================================
# LOGGING CONFIGURATION
# ============================================================================

variable "alb_logs_bucket" {
  type        = string
  description = "S3 bucket name for ALB access logs"
}

variable "alb_logs_prefix" {
  type        = string
  description = "S3 prefix for ALB access logs"
  default     = "alb-logs"
}

variable "flow_logs_retention_days" {
  type        = number
  description = "CloudWatch Logs retention period for VPC Flow Logs (days)"
  default     = 7
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for encrypting CloudWatch Logs (VPC Flow Logs)"
  default     = ""
}

# ============================================================================
# RDS CONFIGURATION
# ============================================================================

variable "rds_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  type        = number
  description = "RDS allocated storage in GB"
  default     = 20
}

variable "rds_engine_version" {
  type        = string
  description = "PostgreSQL engine version"
  default     = "15.8"
}

variable "rds_backup_retention_period" {
  type        = number
  description = "RDS backup retention period in days"
  default     = 7
}

variable "rds_master_username" {
  type        = string
  description = "RDS master username"
  default     = "dbadmin"
}

# ============================================================================
# EC2 CONFIGURATION
# ============================================================================

variable "ec2_instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3a.small"
}

variable "ec2_ami_id" {
  type        = string
  description = "EC2 AMI ID (leave empty for latest Amazon Linux 2023)"
  default     = "ami-0b6c6ebed2801a5cb"
}

# ============================================================================
# CERTIFICATE CONFIGURATION
# ============================================================================

variable "certificate_arn" {
  type        = string
  description = "Existing ACM certificate ARN (leave empty to create new)"
  default     = ""
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 hosted zone ID (leave empty to skip DNS automation)"
  default     = ""
}

variable "create_route53_records" {
  type        = bool
  description = "Auto-create Route53 records for ACM validation and ALB alias"
  default     = false
}

# ============================================================================
# SNS CONFIGURATION
# ============================================================================

variable "alert_email" {
  description = "Email for CloudWatch alarms"
  type        = string
  default     = ""
}

variable "enable_guardduty" {
  type    = bool
  default = true
}

variable "enable_dashboard" {
  type    = bool
  default = true
}

