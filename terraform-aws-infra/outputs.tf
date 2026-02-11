output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Route 53 zone ID of the ALB (for DNS records)"
  value       = aws_lb.this.zone_id
}

output "alb_logs_bucket" {
  description = "S3 bucket name for ALB access logs"
  value       = var.alb_logs_bucket
}

output "oidc_issuer" {
  description = "OIDC issuer URL for Entra ID"
  value       = "https://login.microsoftonline.com/${var.entra_tenant_id}/v2.0"
}

output "oidc_client_id" {
  description = "OIDC client ID (Entra ID application ID)"
  value       = var.entra_client_id
  sensitive   = true
}


