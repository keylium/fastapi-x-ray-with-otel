output "alb_hostname" {
  description = "ALB hostname"
  value       = aws_lb.main.dns_name
}

output "fastapi_ecr_repository_url" {
  description = "URL of the FastAPI ECR repository"
  value       = aws_ecr_repository.fastapi_app.repository_url
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = aws_iam_role.github_actions.arn
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.main.name
}

output "cloudwatch_log_group_fastapi" {
  description = "CloudWatch log group for FastAPI application"
  value       = aws_cloudwatch_log_group.fastapi_app.name
}

output "cloudwatch_log_group_adot" {
  description = "CloudWatch log group for ADOT collector"
  value       = aws_cloudwatch_log_group.adot_collector.name
}
