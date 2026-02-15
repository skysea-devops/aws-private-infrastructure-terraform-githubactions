# Terraform Infrastructure - Phase 4 & 5 Deployment

## Overview
This Terraform configuration deploys a complete AWS infrastructure for running service with:
- Phase 4: RDS PostgreSQL (private subnets, encrypted, backups enabled)
- Phase 5: EC2 instance (public subnet, SSM managed, no SSH)

## Architecture

### Network Layer
- VPC with public and private subnets across 2 AZs
- NAT Gateway for private subnet internet access
- Internet Gateway for public subnets

### Data Layer (Phase 4)
- RDS PostgreSQL in private subnets
- Storage encryption enabled
- Automated backups (7 days retention)
- Credentials stored in Secrets Manager

### Compute Layer (Phase 5)
- EC2 instance in public subnet with public IP
- Managed via SSM Session Manager (no SSH)
- IAM role with least privilege:
  - Read Secrets Manager (RDS + OIDC credentials)
  - Write CloudWatch Logs
  - SSM core permissions

### Security
- ALB with HTTPS + Azure Entra ID OIDC authentication
- Security groups with least privilege
- VPC Flow Logs to CloudWatch
- ALB access logs to S3

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.5.0
3. S3 bucket for Terraform state (created manually)
4. DynamoDB table for state locking (created manually)
5. Azure Entra ID app registration with client secret

## Required Manual Steps Before Apply

### 1. Create Terraform State Backend
```bash
aws s3 mb s3://test-bucket-terraform-state-v1 --region eu-central-1
aws s3api put-bucket-versioning \
  --bucket test-bucket-terraform-state-v1 \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-central-1
```

### 2. Create OIDC Client Secret in Secrets Manager
```bash
aws secretsmanager create-secret \
  --name myproject/dev/entra-oidc-client-secret \
  --secret-string "YOUR_AZURE_ENTRA_CLIENT_SECRET" \
  --region us-east-1
```

### 3. Update terraform.tfvars
Edit `terraform.tfvars` and set:
- `entra_tenant_id` - Your Azure tenant ID
- `entra_client_id` - Your Azure app client ID
- `host_header` - Your domain name (e.g., xxx.example.com)

## Deployment

### Initialize Terraform
```bash
terraform init
```

### Plan Deployment
```bash
terraform plan
```

### Apply Configuration
```bash
terraform apply
```

### Important Outputs
After successful deployment, note these outputs:
- `alb_dns_name` - ALB DNS name for Route53 CNAME
- `acm_certificate_arn` - Certificate for DNS validation
- `ec2_instance_id` - Instance ID for SSM connection
- `rds_endpoint` - Database endpoint
- `application_url` - Full application URL

## Post-Deployment Steps

### 1. DNS Configuration
Create a CNAME record pointing your domain to the ALB DNS name:
```
xxx.example.com -> myproject-dev-alb-123456789.us-east-1.elb.amazonaws.com
```

### 2. ACM Certificate Validation
The ACM certificate requires DNS validation. Add the CNAME records shown in ACM console to your DNS provider.

### 3. Connect to EC2 via SSM
```bash
aws ssm start-session --target i-xxxxxxxxxxxxxxxxx --region us-east-1
```

### 4. Check Application Logs
```bash
# On EC2 instance via SSM
sudo docker logs xxx
sudo cat /var/log/user-data.log
```

## Instance Specifications

### RDS PostgreSQL (db.t3.micro)
- vCPU: 2
- RAM: 1 GB
- Storage: 20 GB (gp3 SSD)
- Network: Up to 2,085 Mbps
- Type: Burstable performance
- Use Case: Development/testing workloads

### EC2 Instance (t3.small)
- vCPU: 2
- RAM: 2 GB
- Root Volume: 30 GB (gp3 SSD, encrypted)
- Network: Up to 5 Gbps
- Type: Burstable performance
- Use Case: Small production workloads, app automation

### Alternative Instance Options

#### For Production RDS:
- **db.t3.small**: 2 vCPU, 2 GB RAM (~$30/month)
- **db.t3.medium**: 2 vCPU, 4 GB RAM (~$60/month)
- **db.m6g.large**: 2 vCPU, 8 GB RAM (~$130/month)

#### For Production EC2:
- **t3.medium**: 2 vCPU, 4 GB RAM (~$30/month)
- **t3.large**: 2 vCPU, 8 GB RAM (~$60/month)
- **m6i.large**: 2 vCPU, 8 GB RAM (~$70/month)

To change instance types, update `terraform.tfvars`:
```hcl
rds_instance_class = "db.t3.small"
ec2_instance_type  = "t3.medium"
```

## Resource Costs (Approximate)

### Default Configuration (Dev/Test):
- RDS db.t3.micro (2 vCPU, 1 GB RAM, 20 GB): ~$15/month
- EC2 t3.small (2 vCPU, 2 GB RAM, 30 GB): ~$15/month
- NAT Gateway: ~$33/month + data transfer
- ALB: ~$18/month + LCU charges
- EBS Storage (50 GB total): ~$5/month
- **Total: ~$86/month** (excluding data transfer)

### Production Configuration:
- RDS db.t3.small (2 vCPU, 2 GB RAM, 100 GB): ~$45/month
- EC2 t3.medium (2 vCPU, 4 GB RAM, 50 GB): ~$35/month
- NAT Gateway: ~$33/month + data transfer
- ALB: ~$18/month + LCU charges
- EBS Storage (150 GB total): ~$15/month
- **Total: ~$146/month** (excluding data transfer)

## Security Notes

1. No SSH access - use SSM Session Manager
2. RDS is not publicly accessible
3. EC2 has minimal IAM permissions
4. All traffic encrypted (HTTPS + RDS encryption)
5. VPC Flow Logs enabled for network monitoring

## Cleanup

```bash
terraform destroy
```

Note: Manually delete secrets from Secrets Manager if no longer needed.
