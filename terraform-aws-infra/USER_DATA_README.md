# EC2 User Data Script - Overview


### 1. System Setup
```bash
dnf update -y
dnf install -y docker aws-cli jq git
```
- Updates all system packages
- Installs Docker (for running containers)
- Installs AWS CLI (to access AWS services)
- Installs jq (JSON parser)
- Installs git (for deployment workflows)

### 2. Docker Configuration
```bash
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user
```
- Enables Docker to start on boot
- Starts Docker service immediately
- Adds ec2-user to docker group (allows running docker without sudo)

### 3. Register Instance to ALB Target Group
```bash
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

aws elbv2 register-targets \
  --target-group-arn ${target_group_arn} \
  --targets Id=$PRIVATE_IP \
  --region ${aws_region}
```
- Gets instance metadata from AWS metadata service (169.254.169.254)
- Registers the instance to Application Load Balancer target group
- ALB will now route traffic to this instance


## Execution Flow

```
EC2 Launch
    ↓
User Data Script Starts
    ↓
1. Update system & install packages (docker, aws-cli, jq, git)
    ↓
2. Configure Docker service
    ↓
3. Register instance to ALB target group
    ↓
Script Complete - Ready for Application Deployment
```

## Application Deployment (Separate Process)

After infrastructure is ready, deploy app via:

### Option 2: GitHub Actions Workflow
See `.github/workflows/deploy.yml` for automated deployment example.

### Option 3: Custom CI/CD Pipeline
Use the provided `deploy_app.sh` script in your CI/CD tool.

## Files Created by User Data

- `/var/log/user-data.log` - User data execution log

## Variables Passed from Terraform

The script uses these variables from `ec2.tf`:
- `${project}`: Project name
- `${env}`: Environment (dev/prod)
- `${aws_region}`: AWS region
- `${service_port}`: Application port (5678)
- `${rds_secret_name}`: Secrets Manager secret name for RDS
- `${target_group_arn}`: ALB target group ARN

## Logging

All output is logged to:
```
/var/log/user-data.log
```

To check execution:
```bash
# Connect via SSM
aws ssm start-session --target i-xxxxx

# View user data logs
sudo cat /var/log/user-data.log

# Check deployment info
cat /home/ec2-user/deployment-info.env
```


## Troubleshooting

If instance is not ready:

1. **Check user data execution:**
   ```bash
   sudo cat /var/log/user-data.log
   ```

2. **Check Docker status:**
   ```bash
   sudo systemctl status docker
   ```

3. **Check target group registration:**
   - AWS Console → EC2 → Target Groups → Check targets
   - Should show instance in "healthy" state

4. **Check deployment info file:**
   ```bash
   cat /home/ec2-user/deployment-info.env
   ```

## Security Features

- No SSH access (uses SSM Session Manager)
- No hardcoded credentials
- Minimal user data (only infrastructure)
- Application credentials fetched at deployment time
- Instance profile has minimal IAM permissions
