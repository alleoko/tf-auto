variable "aws_region"    { 
    type = string 
    default = "ap-southeast-1" 
    }
variable "app_name"      { 
    type = string 
    default = "magi-app-stg" 
    }
variable "environment"   { 
    type = string 
    default = "staging" 
    }
variable "vpc_cidr"      { 
    type = string 
    default = "10.0.0.0/16" 
    }
variable "public_subnet_cidrs"  { 
    type = list(string) 
    default = ["10.0.1.0/24", "10.0.2.0/24"] 
    }
variable "private_subnet_cidrs" { 
    type = list(string) 
    default = ["10.0.10.0/24", "10.0.11.0/24"] 
    }
variable "webapp_port"   { 
    type = number 
    default = 3000 
    }
variable "api_port"      { 
    type = number 
    default = 30000 
    }
variable "db_name"       { 
    type = string 
    default = "appdb" 
    }
variable "db_username"   { 
    type = string 
    default = "admin1234" 
    }
variable "db_password"   { 
    type = string 
    sensitive = true 
    }
variable "db_instance_class" { 
    type = string 
    default = "db.t3.micro" 
    }
variable "jwt_token"     { 
    type = string 
    sensitive = true 
    }
variable "service_secret" { 
    type = string 
    sensitive = true 
    }
