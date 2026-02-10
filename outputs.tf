############################################
# outputs.tf — Phase 3
############################################

# ── Give to Max Ignatov ───────────────────

output "acm_validation_cname_name" {
  description = "CNAME name for ACM DNS validation → give to Max"
  value       = tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_name
}

output "acm_validation_cname_value" {
  description = "CNAME value for ACM DNS validation → give to Max"
  value       = tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_value
}

output "alb_dns_name" {
  description = "ALB DNS name → Route 53 alias target, give to Max"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID → required for Route 53 alias, give to Max"
  value       = aws_lb.this.zone_id
}

# ── Internal (Phase 4+) ───────────────────

output "alb_arn" {
  value = aws_lb.this.arn
}

output "target_group_arn" {
  description = "Register n8n EC2 instance here in Phase 4"
  value       = aws_lb_target_group.this.arn
}

output "acm_certificate_arn" {
  value = aws_acm_certificate_validation.this.certificate_arn
}

output "oidc_secret_arn" {
  value = aws_secretsmanager_secret.oidc.arn
}
