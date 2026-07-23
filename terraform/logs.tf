# ---------------------------------------------------------------------------
# Centralized logging: one log group for every container, owned by Terraform
# so that awslogs-create-group can stay "false".
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "containerwatch" {
  name              = "/${var.project_name}/containers"
  retention_in_days = var.log_retention_days
  tags              = { Name = "${var.project_name}-logs" }
}
