provider "aws" {
  region  = "ap-southeast-1"
}

resource "aws_s3_bucket" "tfstate" {
  bucket = "magi-app-stg"
  tags = {
    Name        = "magi-app-stg"
    Environment = "staging"
  }
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

#Use this when multiple people or processes run Terraform on the same infrastructure, the lock prevents conflicts. 
#resource "aws_dynamodb_table" "tfstate_lock" {
#  name         = "magi-app-stg-tfstate-lock"
#  billing_mode = "PAY_PER_REQUEST"
#  hash_key     = "LockID"
#  attribute {
#    name = "LockID"
#    type = "S"
#  }
#}