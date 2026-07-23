terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# ---------------------------------------------------------------------------
# Networking: dedicated VPC, public subnet, internet gateway, route table
# ---------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.1.0/24"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-public" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------
# Security group: least-privilege ingress (Section 2.1 of the report)
# ---------------------------------------------------------------------------

resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-sg"
  description = "ContainerWatch: public sample app, admin-only Grafana and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Sample application (public)"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana (administrator CIDR only)"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "SSH (administrator CIDR only)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # Prometheus (9090), Alertmanager (9093), Node Exporter (9100) and
  # cAdvisor (8080) have no ingress rule: they stay on the Docker network.

  egress {
    description = "Image pulls and CloudWatch Logs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg" }
}

# ---------------------------------------------------------------------------
# Compute: EC2 host that boots the Docker Compose stack from user_data
# ---------------------------------------------------------------------------

resource "aws_instance" "monitoring" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.monitoring.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  key_name                    = var.key_name
  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2 only
  }

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = templatefile("${path.module}/user_data.sh", {
    repo_url   = var.repo_url
    aws_region = var.aws_region
    log_group  = aws_cloudwatch_log_group.containerwatch.name
  })

  # The awslogs driver fails at container start if the log group is missing,
  # so the instance must not boot before Terraform has created it.
  depends_on = [aws_cloudwatch_log_group.containerwatch]

  tags = { Name = "${var.project_name}-ec2" }
}
