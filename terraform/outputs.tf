# ==============================================================================
# Root Outputs (Aggregated from Child Modules)
# ==============================================================================

output "environment" {
  description = "Active deployment environment"
  value       = local.environment
}

output "vpc_id" {
  description = "ID of the custom VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.networking.public_subnet_id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.networking.internet_gateway_id
}

output "route_table_id" {
  description = "ID of the public Route Table"
  value       = module.networking.route_table_id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.security.security_group_id
}

output "instance_id" {
  description = "ID of the deployed EC2 server"
  value       = module.compute.instance_id
}

output "instance_public_ip" {
  description = "Public IPv4 address of the deployed EC2 server"
  value       = module.compute.instance_public_ip
}

output "application_url" {
  description = "Public URL to access SERP Hawk CRM"
  value       = "http://${module.compute.instance_public_ip}"
}

output "api_docs_url" {
  description = "Public URL to access FastAPI Swagger Documentation"
  value       = "http://${module.compute.instance_public_ip}/docs"
}

output "ssh_command" {
  description = "Command to SSH connect to the EC2 server"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${module.compute.instance_public_ip}"
}
