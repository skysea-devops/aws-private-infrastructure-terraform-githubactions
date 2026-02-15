# Terraform Infrastructure Deployment

## Overview
Complete AWS infrastructure for running a self-hosted service with:
- RDS PostgreSQL (private subnets, encrypted, automated backups)
- EC2 instance (public subnet, SSM managed, no SSH)
- ALB with HTTPS + Azure Entra ID OIDC authentication

## Architecture

### Network Layer
- VPC with public and private subnets across 2 AZs
- Internet Gateway for public subnet internet access
- NAT Gateway for private subnet egress traffic
- VPC Flow Logs to CloudWatch

### Data Layer
- RDS PostgreSQL in private subnets (not publicly accessible)
- Storage encryption enabled
- Automated backups with configurable retention
- Credentials auto-generated and stored in AWS Secrets Manager

### Compute Layer
- EC2 instance in public subnet with public IPv4
- Managed exclusively via SSM Session Manager (no SSH/bastion)
- IAM role with least privilege permissions:
  - Read secrets from Secrets Manager (RDS + OIDC)
  - Write logs to CloudWatch
  - Describe EC2 tags (for deployment automation)
  - SSM Session Manager core permissions

### Load Balancer & Security
- Application Load Balancer (internet-facing)
- HTTPS-only with TLS 1.3
- Azure Entra ID OIDC authentication at ALB layer
- HTTP to HTTPS automatic redirect
- Security groups with strict ingress/egress rules
- ALB access logs to S3

## Prerequisites

### Tools Required
- AWS CLI configured with appropriate credentials
- Terraform >= 1.5.0
- Access to Azure Portal (for Entra ID app registration)

### AWS Resources Created by Bootstrap
The following resources should already exist (created via `terraform/bootstrap`):
- S3 bucket for Terraform state
- DynamoDB table for state locking
- S3 bucket versioning enabled
- Proper IAM permissions for Terraform execution

## What Terraform Creates Automatically

**Network Infrastructure:**
- VPC, subnets, route tables
- Internet Gateway, NAT Gateway, Elastic IP
- Security groups for ALB, EC2, and RDS

**Database:**
- RDS PostgreSQL instance
- DB subnet group
- Random password generation
- Secrets Manager secret with full DB credentials (auto-created)

**Compute:**
- EC2 instance with user data
- IAM role and instance profile
- CloudWatch log group

**Load Balancer:**
- Application Load Balancer
- Target group with health checks
- HTTPS listener with OIDC authentication
- HTTP listener with redirect (optional)

**Security:**
- ACM certificate for your domain (auto-created if not provided)
- Secrets Manager secrets for OIDC client secret (auto-created)
- VPC Flow Logs configuration
- S3 bucket policy for ALB logs

## What You Need to Provide Manually

### 1. Azure Entra ID App Registration

**Create app in Azure Portal:**
1. Navigate to Azure Portal → App registrations → New registration
2. **Name**: "myproject-alb-oidc" (or your preferred name)
3. **Supported account types**: Accounts in this organizational directory only
4. **Redirect URI**: 
   - Platform: Web
   - URL: `https://YOUR-DOMAIN.com/oauth2/idpresponse`
5. Click **Register**

**Configure the app:**
1. Copy **Application (client) ID** → This is `entra_client_id`
2. Copy **Directory (tenant) ID** → This is `entra_tenant_id`
3. Go to **Certificates & secrets** → Client secrets → New client secret
4. Copy the secret **Value** immediately → This is `entra_client_secret`
5. Go to **API permissions** → Ensure these are present:
   - Microsoft Graph → Delegated → openid
   - Microsoft Graph → Delegated → email
   - Microsoft Graph → Delegated → profile

### 2. DNS Configuration (Post-Deployment)

After `terraform apply`, you must manually create DNS records:

**ACM Certificate Validation:**
- Get validation CNAME from AWS Console → ACM → Your certificate
- Add CNAME record to your DNS provider
- Format: `_xxx.your-domain.com` → `_yyy.acm-validations.aws`

**Application Access:**
- Create CNAME or A record pointing to ALB:
  ```
  your-domain.com → myproject-dev-alb-xxxxx.us-east-1.elb.amazonaws.com
  ```
- Or use Route53 Alias record 

### 3. Update terraform.tfvars

Edit `terraform.tfvars` with your values:

```hcl
# ============================================================================
# PROJECT CONFIGURATION
# ============================================================================

project    = "myproject"        # Your project name
env        = "dev"              # Environment (dev/staging/prod)
aws_region = "us-east-1"        # AWS region

# ============================================================================
# APPLICATION CONFIGURATION
# ============================================================================

host_header = "app.example.com" # Your domain name

# ============================================================================
# AZURE ENTRA ID (OIDC) CONFIGURATION
# ============================================================================

entra_tenant_id     = "12345678-1234-1234-1234-123456789abc"  # From Azure Portal
entra_client_id     = "87654321-4321-4321-4321-abcdef123456"  # From Azure Portal
entra_client_secret = "your-secret-value-here"                # From Azure Portal

# ============================================================================
# S3 CONFIGURATION FOR ALB LOGS
# ============================================================================

alb_logs_bucket = "your-terraform-state-bucket" # Same as backend bucket
```

## Deployment Workflow

This infrastructure uses a **two-step workflow** (typically via GitHub Actions):

### Step 1: Terraform Plan (on Pull Request)
```bash
terraform init
terraform plan -out=tfplan
```
- Triggered automatically on PR creation
- Shows what will be created/changed
- No actual resources are created

### Step 2: Terraform Apply (on Merge to Dev)
```bash
terraform apply tfplan
```
- Triggered automatically on merge
- Creates actual AWS resources


## Important Outputs

After successful deployment, save these outputs:

**Critical outputs:**
- `alb_dns_name` - Use for DNS CNAME record
- `acm_certificate_arn` - Certificate ARN (for validation)
- `ec2_instance_id` - For SSM Session Manager connection
- `rds_endpoint` - Database connection endpoint
- `rds_secret_arn` - Secret containing DB credentials
- `application_url` - Your application URL

## Post-Deployment Steps

### 1. Validate ACM Certificate
1. AWS Console → Certificate Manager
2. Find your certificate
3. Copy CNAME name and value
4. Add CNAME record to DNS provider
5. Wait for validation (usually 5-30 minutes)

### 2. Configure DNS
Create DNS record for your application:
```
app.example.com → CNAME → myproject-dev-alb-xxxxx.region.elb.amazonaws.com
```

## Instance Specifications

### RDS PostgreSQL (db.t3.micro - Default)
- vCPU: 2
- RAM: 1 GB
- Storage: 20 GB (gp3 SSD, encrypted)
- Network: Up to 2,085 Mbps
- Backup retention: 7 days
- Use case: Development/testing

### EC2 Instance (t3.small - Default)
- vCPU: 2
- RAM: 2 GB
- Storage: 30 GB (gp3 SSD, encrypted)
- Network: Up to 5 Gbps
- Use case: Small production workloads

### Production Alternatives

**RDS Options:**
- `db.t3.small`: 2 vCPU, 2 GB RAM (~$30/month)
- `db.t3.medium`: 2 vCPU, 4 GB RAM (~$60/month)
- `db.m6g.large`: 2 vCPU, 8 GB RAM (~$130/month)

**EC2 Options:**
- `t3.medium`: 2 vCPU, 4 GB RAM (~$30/month)
- `t3.large`: 2 vCPU, 8 GB RAM (~$60/month)
- `m6i.large`: 2 vCPU, 8 GB RAM (~$70/month)

Update in `terraform.tfvars`:
```hcl
rds_instance_class = "db.t3.small"
ec2_instance_type  = "t3.medium"
```

## Cost Estimate

### Development/Test (Default Configuration)
| Resource | Specification | Monthly Cost |
|----------|--------------|--------------|
| RDS PostgreSQL | db.t3.micro, 20 GB | ~$15 |
| EC2 Instance | t3.small, 30 GB | ~$15 |
| NAT Gateway | Single AZ | ~$33 |
| ALB | Standard | ~$18 |
| EBS Storage | 50 GB total | ~$5 |
| **Total** | | **~$86/month** |

*Excludes data transfer costs*

### Production Configuration
| Resource | Specification | Monthly Cost |
|----------|--------------|--------------|
| RDS PostgreSQL | db.t3.small, 100 GB | ~$45 |
| EC2 Instance | t3.medium, 50 GB | ~$35 |
| NAT Gateway | Single AZ | ~$33 |
| ALB | Standard | ~$18 |
| EBS Storage | 150 GB total | ~$15 |
| **Total** | | **~$146/month** |

## Security Features

**No SSH Access** - All instance access via SSM Session Manager  
**Encryption at Rest** - RDS, EBS volumes encrypted  
**Encryption in Transit** - HTTPS only (TLS 1.3)  
**Least Privilege IAM** - Minimal permissions for EC2 role  
**Network Isolation** - RDS in private subnets  
**Security Groups** - Strict ingress/egress rules  
**OIDC Authentication** - Azure Entra ID at ALB layer  
**Audit Logging** - VPC Flow Logs, ALB access logs  
**Secrets Management** - No hardcoded credentials  

## File Structure

```
.
├── main.tf                    # ALB, listeners, ACM, secrets, logging
├── vpc-sg.tf                  # VPC, subnets, NAT, security groups
├── rds.tf                     # RDS PostgreSQL, credentials
├── ec2.tf                     # EC2 instance, IAM role
├── providers.tf               # Terraform and provider config
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── terraform.tfvars           # Variable values (customize this)
├── user_data.sh              # EC2 bootstrap script
├── deploy_app.sh             # Application deployment script
└── README.md                 # This file
```

## Troubleshooting


## Cleanup

### Destroy Infrastructure via GitHub Actions (Recommended)

1. **Go to GitHub Actions tab** in your repository
2. **Select "Terraform Destroy Infrastructure" workflow**
3. **Click "Run workflow"**
4. **Fill in the inputs:**
   - Confirmation: Type `destroy` exactly
   - Environment: Select environment to destroy (dev/staging/prod)
5. **Click "Run workflow" button**
6. **Wait for validation and manual approval**
   - An issue will be created for approval
   - Review the Terraform destroy plan
   - Approve the issue to proceed
7. **Monitor the destruction** in Actions tab

**Warning**: This will delete:
- EC2 instance and all data
- RDS database (final snapshot will be created)
- Secrets (mark for deletion, 30-day recovery window)
- Network infrastructure


