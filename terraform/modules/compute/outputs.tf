output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.crm_server.id
}

output "instance_public_ip" {
  description = "Public IPv4 address of the EC2 instance"
  value       = aws_instance.crm_server.public_ip
}

output "instance_private_ip" {
  description = "Private IPv4 address of the EC2 instance"
  value       = aws_instance.crm_server.private_ip
}
