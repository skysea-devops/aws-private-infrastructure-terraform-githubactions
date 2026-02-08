# aws-private-infrastructure-terraform-githubactions
Private AWS infrastructure provisioning using Terraform with S3 remote state, DynamoDB locking, KMS encryption, ALB networking, and GitHub Actions–based CI/CD automation.

## CI/CD Setup

```text
.
├── .github/
│   └── workflows/
│       ├── bootstrap.yml          # Remote state setup
│       ├── terraform-plan.yml     # Terraform plan on pull requests
│       └── terraform-apply.yml    # Apply on main branch
│
├── terraform-remote-state/        # Phase 1: Bootstrap stack
│   ├── main.tf                    # S3, DynamoDB, KMS
│   ├── providers.tf
│   ├── variables.tf
│   └── terraform.tfvars
│
└── terraform-aws-infra/            # Phase 2: Main infrastructure
    ├── main.tf                    # ALB, VPC Flow Logs
    ├── vpc-sg.tf                  # VPC, Subnets, Security Groups
    ├── providers.tf
    ├── variables.tf
    ├── outputs.tf
    └── terraform.tfvars
```

## Phase 1: CI/CD Bootstrap (Must Be Completed First)

This phase prepares secure, keyless access for GitHub Actions to AWS using **OIDC** and sets up the **Terraform remote state infrastructure**.

---

### Step 1: Create AWS OIDC Provider

To allow GitHub Actions to authenticate with AWS, an **OIDC provider** must be configured in AWS IAM.

AWS CLI Setup to your local:

```bash
AWS CLI Local Setup macOS:
# Homebrew
brew install awscli

aws --version

aws configure

write those when asked:
AWS Access Key ID [None]: <your-accesskey>
AWS Secret Access Key [None]: <your-secret-accesskey>
Default region name [None]: <region-name>
Default output format [None]: json

# Account test
aws sts get-caller-identity

```

Run the following command using AWS CLI or create the provider via the AWS Console.

```bash
# Using AWS Console or AWS CLI:
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Create IAM Role for GitHub Actions

Next, an IAM role must be created so that GitHub Actions workflows can assume it using `sts:AssumeRoleWithWebIdentity`.

This role explicitly defines:
- **Who can assume it** (GitHub Actions)
- **From which repository** it can be assumed

Create the following trust policy file.

**`role-trust-policy.json`**
```json

  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
```

Create the IAM role using this trust policy:

```bash
aws iam create-role   --role-name GitHubActionsRole   --assume-role-policy-document file://role-trust-policy.json
```

---

### Attach IAM Policy to the Role

Attach an IAM policy that allows Terraform to provision AWS resources.

For simplicity, `AdministratorAccess` is used here.  
**In production environments, this should always be replaced with a least-privilege policy.**

```bash
aws iam attach-role-policy   --role-name GitHubActionsRole   --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

---

### Configure GitHub Repository Secret

GitHub Actions must now be informed which IAM role to assume.

In the GitHub repository:
**Settings → Secrets and variables → Actions → New repository secret**

Create the following secret:

```text
AWS_ROLE_ARN = arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsRole
```

---

### Run Bootstrap Workflow (Terraform Remote State)

After the IAM configuration is complete, run the bootstrap workflow.

This workflow provisions:
- An **S3 bucket** for Terraform remote state
- A **DynamoDB table** for state locking
- A **KMS key** for state encryption

Steps:
1. Go to the **GitHub Actions** page
2. Select the **Bootstrap Remote State** workflow
3. Click **Run workflow**
4. Provide a globally unique S3 bucket name, for example:

```text
my-terraform-state-v1
```

---

### Store Bootstrap Outputs as GitHub Secrets

Once the workflow completes successfully, it will output values required by all subsequent Terraform workflows.

These values **must be stored as GitHub Secrets**:

```text
TF_STATE_BUCKET   # S3 bucket used for Terraform remote state
TF_LOCK_TABLE     # DynamoDB table used for Terraform state locking
KMS_KEY_ARN       # KMS key used to encrypt Terraform state
```
