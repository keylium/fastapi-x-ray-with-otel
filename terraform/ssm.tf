resource "aws_ssm_parameter" "otel_collector_config" {
  name  = "/${var.project_name}/otel-collector-config"
  type  = "String"
  value = file("${path.module}/../config/otel-collector-config.yaml")

  tags = {
    Name = "${var.project_name}-otel-collector-config"
  }
}
