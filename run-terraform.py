#!/bin/bash

# List of Terraform project directories
directories=(
    "/tf-infra/bootstrap"
    "/tf-infra"
    "/tf-api/tf-web-app"
)

for dir in "${directories[@]}"
do
    echo "Processing directory: $dir"
    cd "$dir" || { echo "Failed to change directory to $dir"; continue; }
    
    echo "Running terraform init..."
    terraform init

    echo "Running terraform plan..."
    terraform plan

    echo "Running terraform apply..."
    terraform apply -auto-approve

    echo "Completed processing: $dir"
    echo "------------------------------"
done