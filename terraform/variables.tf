# ==============================================================================
# Root Input Variables with Advanced Validations
# ==============================================================================

variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "aws_region must be a valid AWS region format, e.g., 'us-east-1'."
  }
}

variable "instance_type" {
  description = "AWS EC2 instance type (Free Tier eligible: t3.micro or t2.micro)"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t2.micro", "t4g.micro", "t3.small"], var.instance_type)
    error_message = "instance_type must be a low-cost or Free Tier eligible type (e.g. t3.micro, t2.micro)."
  }
}

variable "key_name" {
  description = "Name of existing AWS EC2 Key Pair for SSH access"
  type        = string
  default     = "serphawk-key"
}

variable "admin_cidr" {
  description = "CIDR block permitted for SSH access (e.g. your IP: x.x.x.x/32 or 0.0.0.0/0)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "vpc_cidr" {
  description = "CIDR block for the custom VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block notation (e.g., 10.0.0.0/16)."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.public_subnet_cidr))
    error_message = "public_subnet_cidr must be a valid IPv4 CIDR block notation (e.g., 10.0.1.0/24)."
  }
}

variable "volume_size" {
  description = "Root EBS storage volume size in GB (Free Tier allows up to 30 GB)"
  type        = number
  default     = 20

  validation {
    condition     = var.volume_size >= 10 && var.volume_size <= 30
    error_message = "volume_size must be between 10 GB and 30 GB to remain strictly Free Tier compliant."
  }
}
