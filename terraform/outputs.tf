output "vpc_id" {
  description = "ID of the custom VPC"
  value       = aws_vpc.crm_vpc.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.crm_public_subnet.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.crm_igw.id
}

output "route_table_id" {
  description = "ID of the public Route Table"
  value       = aws_route_table.crm_public_rt.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.crm_sg.id
}

output "instance_public_ip" {
  description = "Public IPv4 address of the deployed EC2 server"
  value       = aws_instance.crm_server.public_ip
}

output "application_url" {
  description = "Public URL to access SERP Hawk CRM"
  value       = "http://${aws_instance.crm_server.public_ip}"
}

output "api_docs_url" {
  description = "Public URL to access FastAPI Swagger Documentation"
  value       = "http://${aws_instance.crm_server.public_ip}/docs"
}

output "ssh_command" {
  description = "Command to SSH connect to the EC2 server"
  value       = "ssh -i <your-key.pem> ubuntu@${aws_instance.crm_server.public_ip}"
}
