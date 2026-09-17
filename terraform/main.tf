terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. Fetch Latest Ubuntu 24.04 LTS AMI (Free Tier Eligible)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 2. Security Group for CRM Application
resource "aws_security_group" "crm_sg" {
  name        = "serphawk-crm-sg"
  description = "Security group for SERP Hawk CRM V2"

  # HTTP Entry
  ingress {
    description = "Allow HTTP inbound from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS Entry
  ingress {
    description = "Allow HTTPS inbound from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH for Administrator
  ingress {
    description = "Allow SSH inbound from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # Outbound to Internet
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "serphawk-crm-sg"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# 3. User Data script to automatically provision Docker & dependencies
locals {
  user_data = <<-EOF
              #!/bin/bash
              set -e

              # System update
              apt-get update -y
              apt-get install -y ca-certificates curl gnupg git

              # Install Docker Official Repo
              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              chmod a+r /etc/apt/keyrings/docker.gpg

              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

              # Enable Docker for ubuntu user
              usermod -aG docker ubuntu
              systemctl enable docker
              systemctl start docker
              EOF
}

# 4. EC2 Instance (Free Tier Eligible)
resource "aws_instance" "crm_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.crm_sg.id]
  associate_public_ip_address = true
  user_data                   = local.user_data

  # Free tier allows up to 30 GB gp3 root volume
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = "serphawk-crm-server"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
