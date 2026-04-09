# terraform-webapp/terraform.tfvars.example
aws_region     = "ap-southeast-1"
app_name       = "magi-app-stg"
environment    = "staging"
tfstate_bucket = "magi-app-stg-tfstate"

#Git Repo for APIs and webapp
github_repo   = "alejo-nervetech/magi-dup-webapp"
github_branch = "development"

task_cpu      = 256
task_memory   = 512
desired_count = 1

