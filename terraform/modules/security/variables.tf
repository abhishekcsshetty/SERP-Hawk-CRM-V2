variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "admin_cidr" {
  description = "CIDR block permitted for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "environment" {
  description = "Deployment environment name (e.g. dev, prod)"
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
