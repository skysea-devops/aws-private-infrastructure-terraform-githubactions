#!/bin/bash
set -e

exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting infrastructure setup"

dnf update -y
dnf install -y docker aws-cli jq git

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user

aws configure set region ${aws_region}

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

echo "Registering instance to target group"
aws elbv2 register-targets \
  --target-group-arn ${target_group_arn} \
  --targets Id=$PRIVATE_IP \
  --region ${aws_region}


echo "Infrastructure setup completed. Ready for application deployment via workflow."
