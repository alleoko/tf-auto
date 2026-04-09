aws_region    = "ap-southeast-1"
app_name      = "magi-app-stg"
environment   = "staging"

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

webapp_port = 3000
api_port    = 30000

db_name           = "appdb"
db_username       = "admin1234"
db_password       = "change-me"
db_instance_class = "db.t2.micro"

jwt_token      = "change-me"
service_secret = "change-me"
