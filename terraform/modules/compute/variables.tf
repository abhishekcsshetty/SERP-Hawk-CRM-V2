variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where instance will be deployed"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID attached to instance"
  type        = string
}

variable "volume_size" {
  description = "Root EBS storage volume size in GB"
  type        = number
  default     = 20
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
