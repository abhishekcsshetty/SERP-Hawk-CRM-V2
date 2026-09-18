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
