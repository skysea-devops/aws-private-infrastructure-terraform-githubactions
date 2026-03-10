# aws-private-infrastructure-terraform-githubactions
Private AWS infrastructure provisioning using Terraform with S3 remote state, DynamoDB locking, KMS encryption, and GitHub Actions–based CI/CD automation. 

In the first phase, it ensures the infrastructure is version-controlled and repeatable, while S3 remote state with DynamoDB locking prevents conflicts and state corruption, and KMS encryption protects sensitive infrastructure data.

In the terraform-aws-infra stage, a Virtual Private Cloud (VPC) is created with public subnets distributed across multiple Availability Zones to ensure high availability. An Internet Gateway and public route tables enable inbound and outbound internet access for edge components. Traffic is terminated at an Application Load Balancer (ALB), which handles HTTPS traffic using an ACM-managed SSL/TLS certificate and enforces secure communication via HTTP-to-HTTPS redirection.

Security is implemented using Security Groups, ensuring that only required traffic flows between the ALB, application services, and the database layer. 

VPC Flow Logs are enabled and sent to CloudWatch Logs to provide visibility into network traffic and support auditing and troubleshooting.


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


