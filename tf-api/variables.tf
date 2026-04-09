variable "aws_region"     { 
    type = string 
    default = "ap-southeast-1" 
    }
variable "app_name"       { 
    type = string 
    default = "magi-app-stg" 
    }
variable "environment"    { 
    type = string 
    default = "staging"
    }
variable "tfstate_bucket" { 
    type = string 
    default = "magi-app-stg" 
    }
variable "github_repo"    { 
    type = string 
    }
variable "github_branch"  { 
    type = string 
    default = "development" 
    }
variable "task_cpu"       { 
    type = number 
    default = 256 
    }
variable "task_memory"    { 
    type = number 
    default = 512 
    }
variable "desired_count"  { 
    type = number 
    default = 2 
    }
variable "users_api_url"     { type = string }
variable "patient_api_url"   { type = string }
variable "facility_api_url"  { type = string }
variable "guarantor_api_url" { type = string }
variable "inventory_api_url" { type = string }
variable "reports_api_url"   { type = string }
