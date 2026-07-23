variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix applied to every resource"
  type        = string
  default     = "containerwatch"
}

variable "instance_type" {
  description = "EC2 instance type (t3.small: 2 vCPU / 2 GiB, sized for six containers)"
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB (Prometheus TSDB plus Docker images)"
  type        = number
  default     = 30
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period"
  type        = number
  default     = 14
}

variable "admin_cidr" {
  description = "Administrator public IP in CIDR form, for example 203.0.113.10/32"
  type        = string
}

variable "key_name" {
  description = "Name of an existing EC2 key pair, used for SSH and for CI/CD deployment"
  type        = string
}

variable "repo_url" {
  description = "Public GitHub repository clone URL"
  type        = string
}
