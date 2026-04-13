import os
import subprocess
import sys

directories = [
    "/tf-infra",
 #   "/path/to/terraform2",
 #   "/path/to/terraform3",
 #   "/path/to/terraform4",
 #   "/path/to/terraform5",
 #   "/path/to/terraform6"
]

for i, dir_path in enumerate(directories, start=1):
    print(f"Running Terraform in: {dir_path}")
    os.chdir(dir_path)
    
    # Run terraform init
    init_process = subprocess.run("terraform init -input=false", shell=True, capture_output=True, text=True)
    if init_process.returncode != 0:
        print(f"Failed to initialize in {dir_path}")
        print(init_process.stderr)
        sys.exit(1)  # Exit if init fails

    # Run terraform apply
    apply_process = subprocess.run("terraform apply -auto-approve", shell=True, capture_output=True, text=True)
    if apply_process.returncode != 0:
        print(f"Terraform apply failed in {dir_path}")
        print(apply_process.stderr)
        sys.exit(1)  # Exit if apply fails

    print(f"Successfully applied in {dir_path}\n")