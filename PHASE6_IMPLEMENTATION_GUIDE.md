# SECRETS MANAGEMENT IMPLEMENTATION GUIDE

Flow:

```
┌─────────────────┐
│ GitHub Secrets  │  (Source of truth)
└────────┬────────┘
         │
         │ GitHub Actions writes
         ↓
┌─────────────────────────┐
│ AWS Secrets Manager     │  (Containers created by Terraform)
│  - n8n/encryption_key   │
│  - n8n/db_password      │
│  - n8n/entra_secret     │
└────────┬────────────────┘
         │
         │ EC2 reads (via IAM role)
         ↓
┌─────────────────┐
│ EC2 Container   │
│ (.env file)     │
└─────────────────┘
```

---

##  Implementation Steps

### Step 1: Terraform - Create Secret Containers

**File:** `secrets-manager.tf`

```hcl
resource "aws_secretsmanager_secret" "n8n_encryption_key" {
  name = "n8n/encryption_key"
  # No secret_string here - GitHub Actions will populate
}

resource "aws_secretsmanager_secret_version" "n8n_encryption_key" {
  secret_id     = aws_secretsmanager_secret.n8n_encryption_key.id
  secret_string = "PLACEHOLDER"  # Will be replaced by GitHub Actions
  
  lifecycle {
    ignore_changes = [secret_string]  # ← Important!
  }
}
```

**Why `ignore_changes`?**
- Terraform creates container
- GitHub Actions updates value
- Terraform won't overwrite on next apply

---

### Step 2: IAM Permissions

**EC2 Role - Read Access:**

```hcl
data "aws_iam_policy_document" "ec2_secrets_read" {
  statement {
    sid    = "ReadN8NSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      aws_secretsmanager_secret.n8n_encryption_key.arn,
      aws_secretsmanager_secret.entra_client_secret.arn
    ]
  }
}
```

**GitHubActionsRole - Write Access:**

```hcl
# Attach to existing GitHubActionsRole
data "aws_iam_policy_document" "github_actions_secrets_write" {
  statement {
    sid    = "WriteN8NSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecret"
    ]
    resources = [
      aws_secretsmanager_secret.n8n_encryption_key.arn
    ]
  }
}
```

---

### Step 3: Resource-Based Policies

```hcl
resource "aws_secretsmanager_secret_policy" "n8n_encryption_key" {
  secret_arn = aws_secretsmanager_secret.n8n_encryption_key.arn
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2Read"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ec2_service.arn
        }
        Action   = "secretsmanager:GetSecretValue"
        Resource = "*"
      },
      {
        Sid    = "AllowGitHubActionsWrite"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::ACCOUNT:role/GitHubActionsRole"
        }
        Action   = "secretsmanager:PutSecretValue"
        Resource = "*"
      }
    ]
  })
}
```

---

### Step 4: GitHub Actions - Populate Secrets

**Workflow:** `populate-secrets.yml` (manual trigger)

```yaml
- name: Populate AWS Secrets Manager
  env:
    SECRET_VALUE: ${{ secrets.N8N_ENCRYPTION_KEY }}
  run: |
    aws secretsmanager put-secret-value \
      --secret-id "n8n/encryption_key" \
      --secret-string "$SECRET_VALUE"
```

**When to run:**
- After `terraform apply` (creates containers)
- When secrets change
- Manual: `workflow_dispatch`

---

### Step 5: Update Deploy Workflow

**OLD (Non-compliant):**
```yaml
- name: Build .env
  run: |
    cat > .env << EOF
    N8N_ENCRYPTION_KEY=${{ secrets.N8N_ENCRYPTION_KEY }}  # ❌
    EOF
```

**NEW (Phase 6 compliant):**
```yaml
- name: Build .env from AWS Secrets Manager
  run: |
    # Fetch from AWS Secrets Manager
    N8N_KEY=$(aws secretsmanager get-secret-value \
      --secret-id "n8n/encryption_key" \
      --query 'SecretString' --output text)
    
    cat > .env << EOF
    N8N_ENCRYPTION_KEY=${N8N_KEY}  # ✅ From AWS
    EOF
```

---

## 📋 Deployment Flow (Phase 6)

### One-Time Setup:

```bash
# 1. Apply Terraform (creates secret containers)
terraform apply

# 2. Populate secrets via GitHub Actions
gh workflow run populate-secrets.yml

# 3. Verify
aws secretsmanager get-secret-value --secret-id "n8n/encryption_key"
```

### Regular Deployment:

```bash
# Push to dev branch
git push origin dev

# GitHub Actions deploy workflow:
#   1. Reads from AWS Secrets Manager ✅
#   2. Builds .env
#   3. Deploys to EC2
```

---

##  Compliance Checklist

- [ ] Terraform creates secret **containers** only
- [ ] Terraform does NOT contain real secret values
- [ ] Terraform does NOT output secret values
- [ ] GitHub Secrets store actual values
- [ ] GitHub Actions workflow writes GitHub Secrets → AWS Secrets Manager
- [ ] EC2 IAM role has `secretsmanager:GetSecretValue` permission
- [ ] GitHubActionsRole has `secretsmanager:PutSecretValue` permission
- [ ] Resource-based policies limit access to required roles only
- [ ] Deploy workflow reads from AWS Secrets Manager (not GitHub Secrets)
- [ ] `lifecycle { ignore_changes = [secret_string] }` set on secret versions

---

##  Secrets Inventory

### Secrets to Manage:

| Secret | Secrets Manager Name | GitHub Secret | Used By |
|--------|---------------------|---------------|---------|
| **n8n Encryption Key** | `n8n/encryption_key` | `N8N_ENCRYPTION_KEY` | n8n container |
| **DB Password** | `myproject/dev/rds-credentials` | (auto-generated) | n8n container |
| **Entra Client Secret** | `n8n/entra_oidc_client_secret` | `ENTRA_CLIENT_SECRET` | ALB OIDC |
| **Workflow API Keys** | `n8n/api/*` | Various | n8n workflows |

---

