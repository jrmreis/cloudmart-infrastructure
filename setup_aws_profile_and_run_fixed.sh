#!/bin/bash
# Setup AWS profile and run Ansible playbook

# Default values
AWS_REGION="us-east-1"
AWS_OUTPUT="json"
EKS_CLUSTER_NAME="cloudmart-cluster"
KUBERNETES_VERSION="1.32"

# Display banner
echo "========================================"
echo "CloudMart Infrastructure Setup"
echo "========================================"

# Get AWS credentials
read -p "Enter AWS Access Key ID: " AWS_ACCESS_KEY
read -s -p "Enter AWS Secret Access Key: " AWS_SECRET_KEY
echo

# Set up AWS profile
echo "Setting up AWS profile 'eksuser'..."
aws configure set aws_access_key_id "$AWS_ACCESS_KEY" --profile eksuser
aws configure set aws_secret_access_key "$AWS_SECRET_KEY" --profile eksuser
aws configure set region "$AWS_REGION" --profile eksuser
aws configure set output "$AWS_OUTPUT" --profile eksuser

# Verify AWS profile
echo "Verifying AWS profile 'eksuser'..."
if aws configure list --profile eksuser &>/dev/null; then
    echo "AWS profile 'eksuser' configured successfully."
else
    echo "Failed to configure AWS profile 'eksuser'. Exiting."
    exit 1
fi

# Set default profile for this session
export AWS_PROFILE=eksuser
export AWS_DEFAULT_REGION=$AWS_REGION

# Verify AWS access
echo "Verifying AWS access..."
if aws sts get-caller-identity &>/dev/null; then
    echo "AWS credentials are valid."
else
    echo "Failed to verify AWS credentials. Exiting."
    exit 1
fi

# Create variables file for Ansible
echo "Creating Ansible variables file..."
cat > ansible_vars.yml << EOF
---
aws_access_key: "$AWS_ACCESS_KEY"
aws_secret_key: "$AWS_SECRET_KEY"
aws_region: "$AWS_REGION"
aws_output_format: "$AWS_OUTPUT"
eks_cluster_name: "$EKS_CLUSTER_NAME"
kubernetes_version: "$KUBERNETES_VERSION"
EOF

# Run Ansible playbook
echo "Running Ansible playbook..."
ansible-playbook ansible/playbooks/cloudmart_infrastructure.yml \
    -i 'localhost,' \
    --connection=local \
    -e "ansible_python_interpreter=/usr/bin/python3" \
    -e "@ansible_vars.yml" \
    -e "@ansible/group_vars/combined.yml" \
    -e "@ansible/group_vars/dev.yml" \
    --become

# Check if playbook execution was successful
if [ $? -eq 0 ]; then
    echo "Ansible playbook execution completed successfully."
else
    echo "Ansible playbook execution failed."
    exit 1
fi

echo "========================================"
echo "CloudMart Infrastructure Setup Completed"
echo "========================================"
