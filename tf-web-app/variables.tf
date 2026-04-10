###############################################################################
# variables.tf
###############################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "magi-app-stg"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "staging"
}

variable "github_repo" {
  description = "GitHub repo in owner/repo format"
  type        = string
  default     = "alejo-nervetech/magi-dup-web"
}

variable "github_branch" {
  description = "GitHub branch"
  type        = string
  default     = "development"
}

variable "task_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Initial ECS task count"
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Auto-scaling minimum"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Auto-scaling maximum"
  type        = number
  default     = 5
}
