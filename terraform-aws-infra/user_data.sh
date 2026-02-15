#!/bin/bash
set -e

exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting user data script"

dnf update -y
dnf install -y docker aws-cli jq

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user

aws configure set region ${aws_region}

echo "Fetching RDS credentials from Secrets Manager"
RDS_SECRET=$(aws secretsmanager get-secret-value --secret-id ${rds_secret_name} --query SecretString --output text)
DB_HOST=$(echo $RDS_SECRET | jq -r '.host')
DB_PORT=$(echo $RDS_SECRET | jq -r '.port')
DB_NAME=$(echo $RDS_SECRET | jq -r '.dbname')
DB_USER=$(echo $RDS_SECRET | jq -r '.username')
DB_PASS=$(echo $RDS_SECRET | jq -r '.password')

echo "Starting app container"
docker run -d \
  --name app \
  --restart unless-stopped \
  -p ${service_port}:5678 \
  -e DB_TYPE=postgresdb \
  -e DB_POSTGRESDB_HOST=$DB_HOST \
  -e DB_POSTGRESDB_PORT=$DB_PORT \
  -e DB_POSTGRESDB_DATABASE=$DB_NAME \
  -e DB_POSTGRESDB_USER=$DB_USER \
  -e DB_POSTGRESDB_PASSWORD=$DB_PASS \
  -e APP_PROTOCOL=http \
  -e APP_PORT=5678 \
  -e WEBHOOK_URL=https://${project}-${env}.example.com \
  -v app_data:/home/node/.app \
  appio/app

echo "Waiting for app to be healthy"
sleep 30

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

echo "Registering instance to target group"
aws elbv2 register-targets \
  --target-group-arn ${target_group_arn} \
  --targets Id=$PRIVATE_IP \
  --region ${aws_region}

echo "User data script completed"
