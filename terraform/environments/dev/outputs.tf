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

output "private_db_subnet_ids" {
  description = "IDs of the development private database subnets."
  value       = module.networking.private_db_subnet_ids
}

output "private_db_route_table_id" {
  description = "ID of the development private database route table."
  value       = module.networking.private_db_route_table_id
}

output "alb_security_group_id" {
  description = "ID of the development ALB security group."
  value       = module.security.alb_security_group_id
}

output "application_security_group_id" {
  description = "ID of the development application security group."
  value       = module.security.application_security_group_id
}

output "database_security_group_id" {
  description = "ID of the development database security group."
  value       = module.security.database_security_group_id
}

output "application_role_name" {
  description = "Name of the development application IAM role."
  value       = module.iam.application_role_name
}

output "application_role_arn" {
  description = "ARN of the development application IAM role."
  value       = module.iam.application_role_arn
}

output "application_instance_profile_name" {
  description = "Name of the development application EC2 instance profile."
  value       = module.iam.application_instance_profile_name
}

output "application_instance_profile_arn" {
  description = "ARN of the development application EC2 instance profile."
  value       = module.iam.application_instance_profile_arn
}
