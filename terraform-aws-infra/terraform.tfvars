# ============================================================================
# PROJECT CONFIGURATION
# ============================================================================

project    = "myproject"
env        = "dev"
aws_region = "us-east-1"

# ============================================================================
# NETWORK CONFIGURATION
# ============================================================================

vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
azs                 = [] # if blank first 2 AZs

# ============================================================================
# APPLICATION CONFIGURATION
# ============================================================================

service_app_port     = 5678
health_check_path    = "/"
host_header          = "xxx.example.com" # Write here domain name
enable_http_redirect = true

# ============================================================================
# AZURE ENTRA ID (OIDC) CONFIGURATION
# ============================================================================

entra_tenant_id      = "YOUR-TENANT-ID-HERE"     # Azure Portal → Azure Active Directory → Overview → Tenant ID
entra_client_id      = "YOUR-CLIENT-ID-HERE"     # Azure Portal → App registrations → Your App → Application (client) ID
# entra_client_secret is provided via GitHub Secrets (TF_VAR_entra_client_secret)
oidc_session_timeout = 3600

# ============================================================================
# S3 CONFIGURATION FOR ALB LOGS
# ============================================================================

alb_logs_bucket = "" # Leave empty to disable ALB access logs
alb_logs_prefix = "alb-logs"

# ============================================================================
# VPC FLOW LOGS CONFIGURATION
# ============================================================================

flow_logs_retention_days = 7
kms_key_arn              = "" # if blank KMS encryption not used

# ============================================================================
# RDS CONFIGURATION
# ============================================================================

rds_instance_class          = "db.t3.micro"
rds_allocated_storage       = 20
rds_engine_version          = "17.2"
rds_backup_retention_period = 7
rds_master_username         = "dbadmin"

# ============================================================================
# EC2 CONFIGURATION
# ============================================================================

ec2_instance_type = "t3.small"
ec2_ami_id        = "" # if blank uses latest Amazon Linux 2023

# ============================================================================
# CERTIFICATE CONFIGURATION
# ============================================================================

certificate_arn = "arn:aws:acm:us-east-1:594515826734:certificate/4f53bb36-eea6-4c61-bd31-e79376187576" # if blank creates new ACM certificate
