# ==============================================================================
# SERP Hawk CRM V2 - Root Terraform Architecture
# Orchestrates Child Modules (Networking, Security, Compute)
# Multi-Environment Workspaces, Centralized Tags, and Zero-Downtime State Moves
# ==============================================================================

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

# ------------------------------------------------------------------------------
# 1. Networking Module (VPC, IGW, Subnet, Route Table)
# ------------------------------------------------------------------------------
module "networking" {
  source = "./modules/networking"

  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = local.availability_zone
  environment        = local.environment
  tags               = local.common_tags
}

# ------------------------------------------------------------------------------
# 2. Security Module (Security Groups & Least-Privilege Rules)
# ------------------------------------------------------------------------------
module "security" {
  source = "./modules/security"

  vpc_id      = module.networking.vpc_id
  admin_cidr  = var.admin_cidr
  environment = local.environment
  tags        = local.common_tags
}

# ------------------------------------------------------------------------------
# 3. Compute Module (Ubuntu AMI, 2GB Swap, Docker Engine, EC2 Instance)
# ------------------------------------------------------------------------------
module "compute" {
  source = "./modules/compute"

  instance_type     = var.instance_type
  key_name          = var.key_name
  subnet_id         = module.networking.public_subnet_id
  security_group_id = module.security.security_group_id
  volume_size       = var.volume_size
  environment       = local.environment
  tags              = local.common_tags
}

# ------------------------------------------------------------------------------
# 4. Zero-Downtime State Refactoring (Terraform 1.1+ 'moved' blocks)
# These blocks cleanly migrate existing monolithic state into modular namespaces
# with 0 destructions, 0 recreations, and 0 downtime for the running EC2 server.
# ------------------------------------------------------------------------------
moved {
  from = aws_vpc.crm_vpc
  to   = module.networking.aws_vpc.crm_vpc
}

moved {
  from = aws_internet_gateway.crm_igw
  to   = module.networking.aws_internet_gateway.crm_igw
}

moved {
  from = aws_subnet.crm_public_subnet
  to   = module.networking.aws_subnet.crm_public_subnet
}

moved {
  from = aws_route_table.crm_public_rt
  to   = module.networking.aws_route_table.crm_public_rt
}

moved {
  from = aws_route_table_association.crm_public_rta
  to   = module.networking.aws_route_table_association.crm_public_rta
}

moved {
  from = aws_security_group.crm_sg
  to   = module.security.aws_security_group.crm_sg
}

moved {
  from = aws_instance.crm_server
  to   = module.compute.aws_instance.crm_server
}
