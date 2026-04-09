###############################################################################
# terraform-infra/main.tf  –  Foundation: VPC, RDS, ECS Cluster, ALBs, IAM
# Bootstrap then Infra
###############################################################################

terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket = "magi-app-stg"
    key    = "infra/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

provider "aws" { region = var.aws_region }

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" { state = "available" }

locals {
  common_tags = {
    Project     = var.app_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Layer       = "infra"
  }
}
