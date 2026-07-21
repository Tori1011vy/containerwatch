variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "containerwatch"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "admin_cidr" {
  description = "Your public IP in CIDR format, for example 203.0.113.10/32"
  type        = string
}

variable "repo_url" {
  description = "Public GitHub repository clone URL"
  type        = string
}
