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
  default     = "eu-central-1"
}

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

variable "service_app_port" {
  type        = number
  description = "Application port for the service (e.g., n8n runs on 5678)"
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

variable "entra_tenant_id" {
  type        = string
  description = "Azure Entra ID tenant ID for OIDC authentication"
}

variable "entra_client_id" {
  type        = string
  description = "Azure Entra ID application (client) ID"
}

variable "oidc_session_timeout" {
  type        = number
  description = "OIDC session timeout in seconds (also used for ALB stickiness)"
  default     = 3600
}

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
