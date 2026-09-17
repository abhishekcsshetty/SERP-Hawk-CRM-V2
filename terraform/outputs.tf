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
