# ============================================================================
# MONITORING MODULE CALL
# ============================================================================
# File: monitoring-module.tf (terraform-aws-infra/ root)


module "monitoring" {
  source = "./monitoring"
  
  # Basic configuration
  project    = var.project
  env        = var.env
  aws_region = var.aws_region
  
  # Monitoring configuration
  alert_email      = var.alert_email
  enable_guardduty = var.enable_guardduty
  enable_dashboard = var.enable_dashboard
  
  # Resource references
  alb_arn_suffix          = aws_lb.this.arn_suffix
  target_group_arn_suffix = aws_lb_target_group.service.arn_suffix
  ec2_instance_id         = aws_instance.service.id
  rds_instance_id         = aws_db_instance.this.id
  
  # Tags
  tags = local.tags
}
