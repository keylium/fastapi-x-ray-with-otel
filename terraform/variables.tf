variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "fastapi-xray-otel"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_image" {
  description = "Container image for FastAPI application"
  type        = string
  default     = "public.ecr.aws/docker/library/python:3.11-slim"
}

variable "adot_image" {
  description = "ADOT Collector image"
  type        = string
  default     = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
}

variable "cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  type        = number
  default     = 512
}

variable "memory" {
  description = "Fargate instance memory to provision (in MiB)"
  type        = number
  default     = 1024
}

variable "app_count" {
  description = "Number of docker containers to run"
  type        = number
  default     = 2
}
