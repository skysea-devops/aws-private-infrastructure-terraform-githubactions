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
