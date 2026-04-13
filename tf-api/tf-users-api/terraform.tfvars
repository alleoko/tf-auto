aws_region    = "ap-southeast-1"
app_name      = "magi-app-stg"
environment   = "staging"

github_repo   = "alejo-nervetech/magi-dup-user-api"
github_branch = "main"

task_cpu      = 256
task_memory   = 512
desired_count = 1
min_capacity  = 1
max_capacity  = 5
db_name     = "appdb"
db_username = "admin1234"
