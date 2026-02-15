output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for s in aws_subnet.public : s.id]
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = [for s in aws_subnet.public : s.cidr_block]
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = local.azs_effective
}

output "alb_security_group_id" {
  description = "Security Group ID for ALB"
  value       = aws_security_group.alb.id
}

output "service_security_group_id" {
  description = "Security Group ID for the service"
  value       = aws_security_group.service.id
}

output "rds_security_group_id" {
  description = "Security Group ID for RDS"
  value       = aws_security_group.rds.id
}

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
  description = "Route 53 zone ID of the ALB"
  value       = aws_lb.this.zone_id
}

output "service_target_group_arn" {
  description = "ARN of the service target group"
  value       = aws_lb_target_group.service.arn
}

output "service_target_group_name" {
  description = "Name of the service target group"
  value       = aws_lb_target_group.service.name
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = aws_lb_listener.https.arn
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = var.enable_http_redirect ? aws_lb_listener.http[0].arn : null
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.service_cert.arn
}

output "acm_certificate_status" {
  description = "Status of the ACM certificate"
  value       = aws_acm_certificate.service_cert.status
}

output "acm_certificate_domain" {
  description = "Domain name of the ACM certificate"
  value       = aws_acm_certificate.service_cert.domain_name
}

output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = aws_flow_log.this.id
}

output "vpc_flow_log_group_name" {
  description = "CloudWatch Log Group name for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow.name
}

output "vpc_flow_log_group_arn" {
  description = "CloudWatch Log Group ARN for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow.arn
}

output "vpc_flow_logs_role_arn" {
  description = "ARN of the IAM role for VPC Flow Logs"
  value       = aws_iam_role.flowlogs.arn
}

output "vpc_flow_logs_role_name" {
  description = "Name of the IAM role for VPC Flow Logs"
  value       = aws_iam_role.flowlogs.name
}

output "alb_logs_bucket" {
  description = "S3 bucket name for ALB access logs"
  value       = var.alb_logs_bucket
}

output "alb_logs_prefix" {
  description = "S3 prefix for ALB access logs"
  value       = var.alb_logs_prefix
}

output "oidc_issuer" {
  description = "OIDC issuer URL for Entra ID"
  value       = "https://login.microsoftonline.com/${var.entra_tenant_id}/v2.0"
}

output "oidc_client_id" {
  description = "OIDC client ID"
  value       = var.entra_client_id
  sensitive   = true
}

output "application_url" {
  description = "Application URL"
  value       = var.host_header != "" ? "https://${var.host_header}" : "https://${aws_lb.this.dns_name}"
}

output "service_port" {
  description = "Application service port"
  value       = var.service_app_port
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.this.endpoint
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.this.db_name
}

output "rds_secret_arn" {
  description = "RDS credentials secret ARN"
  value       = aws_secretsmanager_secret.rds_credentials.arn
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.service.id
}

output "ec2_public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.service.public_ip
}

output "ec2_private_ip" {
  description = "EC2 private IP"
  value       = aws_instance.service.private_ip
}

output "ec2_iam_role_arn" {
  description = "EC2 IAM role ARN"
  value       = aws_iam_role.ec2_service.arn
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.this.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = [for s in aws_subnet.private : s.id]
}
