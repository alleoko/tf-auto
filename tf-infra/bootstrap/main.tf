###############################################################################
# bootstrap/main.tf  –  Creates the S3 bucket for Terraform remote state
# Run this ONCE before applying tf-infra.
# If bucket already exists, run: terraform import aws_s3_bucket.tfstate <bucket-name>
###############################################################################

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_s3_bucket" "tfstate" {
  bucket        = "magi-app-stg-tfstate"
  force_destroy = false

  tags = {
    Name        = "magi-app-stg-tfstate"
    Environment = "staging"
    ManagedBy   = "Terraform"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [bucket]
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "tfstate_bucket" {
  value = aws_s3_bucket.tfstate.bucket
}
