provider "aws" {
  region  = "us-east-1"  # You can change this to your preferred region
  profile = "eksuser"    # Altere para o nome do seu USER (IAM) + "aws configure --profile eksuser"
}

# DynamoDB Tables
resource "aws_dynamodb_table" "cloudmart_products" {
  name           = "cloudmart-products"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  attribute {
    name = "id"
    type = "S"
  }
  
  tags = {
    Name        = "cloudmart-products"
    Environment = "Development"
    Project     = "CloudMart"
  }
}

resource "aws_dynamodb_table" "cloudmart_orders" {
  name           = "cloudmart-orders"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  attribute {
    name = "id"
    type = "S"
  }
  
  tags = {
    Name        = "cloudmart-orders"
    Environment = "Development"
    Project     = "CloudMart"
  }
}

resource "aws_dynamodb_table" "cloudmart_tickets" {
  name           = "cloudmart-tickets"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  attribute {
    name = "id"
    type = "S"
  }
  
  tags = {
    Name        = "cloudmart-tickets"
    Environment = "Development"
    Project     = "CloudMart"
  }
}

# Get the latest Amazon Linux 2 AMI (free tier eligible)
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create a security group for the EC2 instance
resource "aws_security_group" "workstation_sg" {
  name        = "workstation-sg"
  description = "Security group for workstation EC2 instance"

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Note: For production, restrict to your IP
    description = "SSH access"
  }

  # Port 5000 access
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Port 5000 access"
  }

  # Port 5001 access
  ingress {
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Port 5001 access"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "workstation-sg"
  }
}

# Get existing IAM role
data "aws_iam_role" "ec2_admin_role" {
  name = "EC2Admin"
}

# Create an instance profile with the IAM role
resource "aws_iam_instance_profile" "ec2_admin_profile" {
  name = "workstation-profile"
  role = data.aws_iam_role.ec2_admin_role.name
}

# Create ECR Repositories for our applications
resource "aws_ecr_repository" "cloudmart_backend" {
  name                 = "cloudmart-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name        = "cloudmart-backend"
    Environment = "Development"
    Project     = "CloudMart"
  }
}

resource "aws_ecr_repository" "cloudmart_frontend" {
  name                 = "cloudmart-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name        = "cloudmart-frontend"
    Environment = "Development"
    Project     = "CloudMart"
  }
}

# Create the EC2 instance
resource "aws_instance" "workstation" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"  # Free tier eligible
  iam_instance_profile   = aws_iam_instance_profile.ec2_admin_profile.name
  vpc_security_group_ids = [aws_security_group.workstation_sg.id]
  
  # Using a minimal user_data script to install Python for Ansible
  user_data              = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3 python3-pip
  EOF
  user_data_replace_on_change = true
  
  # You can add a key pair for SSH access - MAKE SURE YOU SET THIS!
  key_name = "KeyAWS20241104"
  
  root_block_device {
    volume_size = 20  # Increased from 8 GB to ensure enough space for Docker and applications
    volume_type = "gp3"  # Using gp3 for better performance and still eligible for free tier
    encrypted   = true
  }
  
  tags = {
    Name        = "workstation"
    Environment = "Development"
    Provisioner = "Terraform"
  }

  # Add a dependency to ensure the IAM role is available before the instance is created
  depends_on = [aws_iam_instance_profile.ec2_admin_profile]

  # Enable termination protection
  disable_api_termination = false  # Set to true in production to prevent accidental termination
  
  # Enable detailed monitoring (note: not free tier eligible)
  monitoring = false
  
  # We'll use Ansible for the rest of the configuration
}

# Elastic IP for fixed address
resource "aws_eip" "workstation_eip" {
  instance = aws_instance.workstation.id
  domain   = "vpc"
  
  tags = {
    Name = "workstation-eip"
  }
}

# CloudWatch Log Group for logs retention
resource "aws_cloudwatch_log_group" "workstation_logs" {
  name = "/cloudmart/workstation"
  retention_in_days = 30
  
  tags = {
    Name        = "workstation-logs"
    Environment = "Development"
    Project     = "CloudMart"
  }
}

# Generate a local inventory file for Ansible
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl",
    {
      workstation_ip = aws_eip.workstation_eip.public_ip
      backend_ecr_repo = aws_ecr_repository.cloudmart_backend.repository_url
      frontend_ecr_repo = aws_ecr_repository.cloudmart_frontend.repository_url
    }
  )
  filename = "${path.module}/ansible/inventory.ini"
  
  depends_on = [aws_eip.workstation_eip]
}

# Output the public IP of the instance
output "public_ip" {
  value = aws_eip.workstation_eip.public_ip
}

# Output the public DNS of the instance
output "public_dns" {
  value = aws_instance.workstation.public_dns
}

# Output when setup is complete
output "setup_instructions" {
  value = "Infrastructure provisioned. Run Ansible playbook to complete setup: ansible-playbook -i ansible/inventory.ini ansible/cloudmart_setup.yml"
}

# Output CloudWatch Log Group
output "log_group" {
  value = aws_cloudwatch_log_group.workstation_logs.name
  description = "CloudWatch Log Group for centralized logs"
}

# Output ECR repository URLs
output "backend_ecr_repo" {
  value = aws_ecr_repository.cloudmart_backend.repository_url
}

output "frontend_ecr_repo" {
  value = aws_ecr_repository.cloudmart_frontend.repository_url
}
