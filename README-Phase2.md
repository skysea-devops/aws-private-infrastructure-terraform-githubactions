# Phase 2: Networking + Edge (No NAT)

This phase provisions the **networking and edge layer** of the infrastructure.
All resources are **public-facing** and **no NAT Gateway** is used.

## Manual Resources (Must Be Created Before Terraform Apply)

---

### 1. ACM Certificate (SSL/TLS Certificate)

An ACM certificate is required to enable HTTPS on the Application Load Balancer.

Using AWS Console:
- AWS Console → Certificate Manager → Request certificate

Or using AWS CLI:

```bash
aws acm request-certificate \
  --domain-name xxx.example.com \
  --validation-method DNS \
  --region us-east-1

# After the certificate is created, store the certificate ARN as a GitHub Secret:
# CERTIFICATE_ARN = arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/xxx
```

**Not:** DNS validation requires adding a CNAME record to your domain’s DNS configuration.

### 2. Domain DNS Configuration (Route53 or External DNS Provider)

Two DNS records are required:

```bash
# Certificate validation record (provided by ACM):
CNAME: _xxx.xxx.example.com → _yyy.acm-validations.aws

# Application domain pointing to the ALB (after Terraform apply):
CNAME: xxx.example.com → xxx-dev-alb-1234567890.us-east-1.elb.amazonaws.com
```

## Terraform Apply

After the certificate is created and DNS validation is completed, proceed with Terraform.

```bash
cd terraform-aws-infra
```

Verify the values in variables.tf or terraform.tfvars and ensure that
certificate_arn is correctly set.

Local test (optional)
```bash
terraform init \
  -backend-config="bucket=n8n-selfhosted-terraform-state-v1" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=n8n-dev-terraform-locks" \
  -backend-config="encrypt=true"

terraform plan -var="kms_key_arn=arn:aws:kms:..." -var="certificate_arn=arn:aws:acm:..."
```

**GitHub Actions Workflow:**

1. Create a Pull Request

2. Terraform Plan workflow runs automatically

3. Review the plan output

4. Merge the Pull Request

5. Terraform Apply workflow runs on the main branch

----

## All secrets must be stored under:

Settings → Secrets and variables → Actions

From Phase 1 (Bootstrap)
```bash
# Bootstrap sonrası
AWS_ROLE_ARN         = arn:aws:iam::ACCOUNT_ID:role/GitHubActionsRole
TF_STATE_BUCKET      = n8n-selfhosted-terraform-state-v1
TF_LOCK_TABLE        = n8n-dev-terraform-locks
KMS_KEY_ARN          = arn:aws:kms:us-east-1:ACCOUNT_ID:key/xxx

# Manuelly
CERTIFICATE_ARN      = arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/xxx
```

## Provisioned Resources so far

### Phase 1: Bootstrap

- ✅ S3 Bucket (Terraform remote state)
- ✅ DynamoDB Table (State locking)
- ✅ KMS Key (Encryption)

### Phase 2: Networking

- ✅ VPC (10.0.0.0/16)
- ✅ Public Subnets (2 AZ)
- ✅ Internet Gateway
- ✅ Route Tables
- ✅ Security Groups (ALB, n8n, RDS)
- ✅ Application Load Balancer
- ✅ Target Group
- ✅ HTTPS Listener (443)
- ✅ HTTP Redirect (80 → 443)
- ✅ VPC Flow Logs → CloudWatch

  
