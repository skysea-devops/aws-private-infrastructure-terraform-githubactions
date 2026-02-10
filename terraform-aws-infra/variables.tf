

variable "host_header" {
  type        = string
  description = "Optional host header for routing (e.g. n8n.example.com). Empty means default forward."
  default     = ""
}

variable "health_check_path" {
  type        = string
  description = "Target group health check path"
  default     = "/"
}

variable "entra_tenant_id"      { type = string }
variable "entra_client_id"      { type = string }
variable "oidc_session_timeout" { type = number; default = 28800 }
