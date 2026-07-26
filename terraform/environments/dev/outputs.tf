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

output "launch_template_id" {
  value = module.compute.launch_template_id
}

output "launch_template_name" {
  value = module.compute.launch_template_name
}

output "autoscaling_group_name" {
  value = module.compute.autoscaling_group_name
}

output "autoscaling_group_arn" {
  value = module.compute.autoscaling_group_arn
}

output "amazon_linux_2023_ami_id" {
  value       = module.compute.amazon_linux_2023_ami_id
  sensitive   = true
  description = "Amazon Linux 2023 AMI selected by the compute module."
}
output "load_balancer_dns_name" {
  description = "Public DNS name of the development Application Load Balancer."
  value       = module.load_balancer.load_balancer_dns_name
}

output "load_balancer_arn" {
  description = "ARN of the development Application Load Balancer."
  value       = module.load_balancer.load_balancer_arn
}

output "load_balancer_zone_id" {
  description = "Canonical hosted-zone ID of the development load balancer."
  value       = module.load_balancer.load_balancer_zone_id
}

output "target_group_arn" {
  description = "ARN of the development application target group."
  value       = module.load_balancer.target_group_arn
}

output "target_group_name" {
  description = "Name of the development application target group."
  value       = module.load_balancer.target_group_name
}

output "http_listener_arn" {
  description = "ARN of the development HTTP listener."
  value       = module.load_balancer.http_listener_arn
}

output "database_instance_id" {
  description = "RDS PostgreSQL instance identifier."
  value       = module.database.database_instance_id
}

output "database_endpoint" {
  description = "RDS PostgreSQL endpoint."
  value       = module.database.database_endpoint
}

output "database_address" {
  description = "RDS PostgreSQL hostname."
  value       = module.database.database_address
}

output "database_port" {
  description = "RDS PostgreSQL port."
  value       = module.database.database_port
}

output "database_name" {
  description = "RDS PostgreSQL database name."
  value       = module.database.database_name
}

output "database_credentials_secret_arn" {
  description = "Secrets Manager ARN containing database credentials."
  value       = module.database.database_credentials_secret_arn
}

output "ansible_transfer_bucket_name" {
  description = "S3 bucket used by Ansible for temporary SSM file transfers."
  value       = module.ansible_support.transfer_bucket_name
}

output "ansible_transfer_bucket_arn" {
  description = "ARN of the Ansible SSM transfer bucket."
  value       = module.ansible_support.transfer_bucket_arn
}

output "github_actions_role_name" {
  description = "Name of the IAM role assumed by GitHub Actions."
  value       = module.cicd.github_actions_role_name
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role assumed by GitHub Actions."
  value       = module.cicd.github_actions_role_arn
}

output "github_oidc_subject" {
  description = "GitHub repository and branch trusted by the OIDC role."
  value       = module.cicd.github_oidc_subject
}
