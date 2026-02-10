
# variables.tf — Phase 3


variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "domain_name" {
  description = "e.g. n8n.yourdomain.com"
  type        = string
}

variable "service_app_port" {
  type    = number
  default = 5678
}

variable "health_check_path" {
  type    = string
  default = "/healthz"
}

variable "enable_http_redirect" {
  type    = bool
  default = true
}

variable "alb_logs_bucket" {
  description = "Existing S3 bucket name for ALB access logs"
  type        = string
}

variable "alb_logs_prefix" {
  type    = string
  default = "n8n-alb"
}

variable "entra_tenant_id" {
  description = "Azure tenant ID (GUID)"
  type        = string
}

variable "entra_client_id" {
  description = "Entra ID app registration client ID (GUID)"
  type        = string
}

variable "entra_client_secret" {
  description = "Pass via TF_VAR_entra_client_secret, never in tfvars"
  type        = string
  sensitive   = true
}

variable "oidc_session_timeout" {
  type    = number
  default = 28800
}
