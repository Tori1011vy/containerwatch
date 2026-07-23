#!/bin/bash
set -euxo pipefail

# 1. Base packages
dnf update -y
dnf install -y docker git

# 2. Docker Compose v2 plugin (not shipped with the Amazon Linux docker package)
mkdir -p /usr/local/lib/docker/cli-plugins
curl -sSL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

systemctl enable --now docker
usermod -aG docker ec2-user

# 3. Application and monitoring stack
git clone ${repo_url} /opt/containerwatch
cd /opt/containerwatch

# 4. Runtime configuration. The Grafana password is generated on the instance,
#    so no credential is ever stored in Git or in the Terraform state.
cat > .env <<ENVEOF
AWS_REGION=${aws_region}
CLOUDWATCH_LOG_GROUP=${log_group}
GF_ADMIN_USER=admin
GF_ADMIN_PASSWORD=$(openssl rand -base64 18)
ENVEOF
chmod 600 .env
chown ec2-user:ec2-user .env

# 5. Start the six-container stack
docker compose up -d --build
