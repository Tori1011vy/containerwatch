output "public_ip" {
  description = "Public IPv4 address of the monitoring host (set as the EC2_HOST secret)"
  value       = aws_instance.monitoring.public_ip
}

output "sample_app_url" {
  description = "Public URL of the monitored sample application"
  value       = "http://${aws_instance.monitoring.public_ip}:8000"
}

output "grafana_url" {
  description = "Grafana URL, reachable from the administrator CIDR only"
  value       = "http://${aws_instance.monitoring.public_ip}:3000"
}

output "log_group_name" {
  description = "CloudWatch Logs group receiving every container's output"
  value       = aws_cloudwatch_log_group.containerwatch.name
}
