output "vpc_id" {
  description = "ID of the development VPC."
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block assigned to the development VPC."
  value       = module.networking.vpc_cidr
}

output "availability_zones" {
  description = "Availability Zones used by the development environment."
  value       = module.networking.availability_zones
}

output "public_subnet_ids" {
  description = "IDs of the development public subnets."
  value       = module.networking.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "IDs of the development private application subnets."
  value       = module.networking.private_app_subnet_ids
}

output "nat_gateway_id" {
  description = "ID of the development NAT Gateway."
  value       = module.networking.nat_gateway_id
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the development NAT Gateway."
  value       = module.networking.nat_gateway_public_ip
}
