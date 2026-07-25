output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block assigned to the VPC."
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets ordered by subnet index."
  value = [
    for index in sort(keys(aws_subnet.public)) :
    aws_subnet.public[index].id
  ]
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets ordered by subnet index."
  value = [
    for index in sort(keys(aws_subnet.private_app)) :
    aws_subnet.private_app[index].id
  ]
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.public.id
}

output "private_app_route_table_id" {
  description = "ID of the private application route table."
  value       = aws_route_table.private_app.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway when enabled."
  value       = try(aws_nat_gateway.main[0].id, null)
}

output "nat_gateway_public_ip" {
  description = "Public IPv4 address assigned to the NAT Gateway when enabled."
  value       = try(aws_eip.nat[0].public_ip, null)
}

output "availability_zones" {
  description = "Availability Zones used by the networking module."
  value       = var.availability_zones
}

output "private_db_subnet_ids" {
  description = "IDs of the isolated private database subnets ordered by subnet index."
  value = [
    for index in sort(keys(aws_subnet.private_db)) :
    aws_subnet.private_db[index].id
  ]
}

output "private_db_route_table_id" {
  description = "ID of the isolated private database route table."
  value       = aws_route_table.private_db.id
}
