output "public_ip" {
  value = aws_instance.monitoring.public_ip
}

output "sample_app_url" {
  value = "http://${aws_instance.monitoring.public_ip}:8000"
}

output "grafana_url" {
  value = "http://${aws_instance.monitoring.public_ip}:3000"
}
