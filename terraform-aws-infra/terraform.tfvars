# Project Configuration
project    = "myproject"
env        = "dev"
aws_region = "us-east-1"

# Network Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
azs                  = []  # if blank first 2 AZs

# Application Configuration
service_app_port   = 5678
health_check_path  = "/"
host_header        = "xxx.example.com"  # Write here domian name
enable_http_redirect = true

# Azure Entra ID (OIDC) Configuration
entra_tenant_id      = "YOUR-TENANT-ID-HERE"        # Azure Portal
entra_client_id      = "YOUR-CLIENT-ID-HERE"        # Azure Portal
oidc_session_timeout = 3600

# S3 Configuration for ALB Logs
alb_logs_bucket = "test-bucket-terraform-state-v1"  # Backend Bucket name 
alb_logs_prefix = "alb-logs"

# VPC Flow Logs Configuration
flow_logs_retention_days = 7
kms_key_arn             = ""  # if blank KMS encryption not used

# RDS Configuration
rds_instance_class          = "db.t3.micro"
rds_allocated_storage       = 20
rds_engine_version          = "15.4"
rds_backup_retention_period = 7
rds_master_username         = "dbadmin"

# EC2 Configuration
ec2_instance_type = "t3.small"
ec2_ami_id        = ""  # if blank uses latest Amazon Linux 2023
