###############################################################################
# variables.tf
###############################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "app_name" {
  description = "Application name - prefix for all resources"
  type        = string
  default     = "magi-app-stg"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "staging"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "webapp_port" {
  description = "Web app container port"
  type        = number
  default     = 80
}

variable "api_port" {
  description = "API services container port"
  type        = number
  default     = 3000
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "admin1234"
}

variable "db_password" {
  description = "PostgreSQL master password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "jwt_token" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
}

variable "service_secret" {
  description = "Inter-service shared secret"
  type        = string
  sensitive   = true
}
