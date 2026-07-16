#!/bin/bash
set -euxo pipefail

# Install Docker
dnf update -y
dnf install -y docker
systemctl enable docker
systemctl start docker

# Install CloudWatch agent
dnf install -y amazon-cloudwatch-agent

# Authenticate to ECR and run the app container
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin $(echo "${ecr_image_uri}" | cut -d'/' -f1)

docker run -d \
  --name app \
  --restart unless-stopped \
  -p ${app_port}:${app_port} \
  --log-driver=awslogs \
  --log-opt awslogs-group=/app/${aws_region}/container-logs \
  --log-opt awslogs-create-group=true \
  ${ecr_image_uri}
