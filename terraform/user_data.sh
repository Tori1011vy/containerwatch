#!/bin/bash
set -euxo pipefail
dnf update -y
dnf install -y docker git
systemctl enable --now docker
usermod -aG docker ec2-user
mkdir -p /opt/containerwatch
git clone "${repo_url}" /opt/containerwatch
cd /opt/containerwatch
cat > .env <<EOF
AWS_REGION=${aws_region}
CLOUDWATCH_LOG_GROUP=${log_group}
GF_ADMIN_USER=admin
GF_ADMIN_PASSWORD=ChangeMeImmediately123!
EOF
docker compose up -d --build
