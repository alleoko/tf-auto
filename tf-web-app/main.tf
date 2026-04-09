###############################################################################
# terraform-webapp/main.tf
# Reads shared infra state from terraform-infra.
# Apply terraform-infra FIRST.
###############################################################################

terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket = "magi-app-stg"
    key    = "webapp/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

provider "aws" { region = "ap-southeast-1" }

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "magi-app-stg"
    key    = "infra/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

locals {
  common_tags = {
    Project     = var.app_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "webapp"
  }
}
