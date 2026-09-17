variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "AWS EC2 instance type (Free Tier eligible: t2.micro or t3.micro)"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of existing AWS EC2 Key Pair for SSH access"
  type        = string
  default     = ""
}

variable "admin_cidr" {
  description = "CIDR block permitted for SSH access (e.g. your IP: x.x.x.x/32)"
  type        = string
  default     = "0.0.0.0/0"
}
