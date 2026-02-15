#!/bin/bash
set -eux

# ===== Variables =====
AWS_REGION="${aws_region}"
TARGET_GROUP_ARN="${target_group_arn}"
PROJECT="${project}"
ENV="${env}"

# ===== System Update =====
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release jq git unzip

# ===== Install Docker =====
echo "=== Installing Docker ==="
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu
echo "Docker installed and ubuntu user added to docker group"

# ===== Install AWS CLI v2 =====
echo "=== Installing AWS CLI v2 ==="
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Verify AWS CLI installation
aws --version

# Configure AWS CLI region
aws configure set region "$AWS_REGION"

# ===== Get Instance Metadata (IMDSv2 Compatible) =====
echo "=== Getting instance metadata ==="
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  -s http://169.254.169.254/latest/meta-data/instance-id)

PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  -s http://169.254.169.254/latest/meta-data/local-ipv4)

echo "Instance ID: $INSTANCE_ID"
echo "Private IP: $PRIVATE_IP"

# ===== Register EC2 to Target Group  =====
echo "=== Registering instance to target group ==="
aws elbv2 register-targets \
  --target-group-arn "$TARGET_GROUP_ARN" \
  --targets Id="$PRIVATE_IP" \
  --region "$AWS_REGION"

if [ $? -eq 0 ]; then
  echo "✓ Successfully registered to target group"
else
  echo "✗ Failed to register to target group"
  exit 1
fi

