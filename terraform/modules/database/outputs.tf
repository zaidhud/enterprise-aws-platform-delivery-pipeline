output "database_instance_id" {
  description = "RDS database instance identifier."
  value       = aws_db_instance.application.id
}

output "database_arn" {
  description = "ARN of the RDS database instance."
  value       = aws_db_instance.application.arn
}

output "database_endpoint" {
  description = "RDS database endpoint including the port."
  value       = aws_db_instance.application.endpoint
}

output "database_address" {
  description = "RDS database hostname."
  value       = aws_db_instance.application.address
}

output "database_port" {
  description = "RDS database port."
  value       = aws_db_instance.application.port
}

output "database_name" {
  description = "Initial database name."
  value       = aws_db_instance.application.db_name
}

output "database_subnet_group_name" {
  description = "Name of the RDS subnet group."
  value       = aws_db_subnet_group.application.name
}

output "database_credentials_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager master-user secret."
  value       = aws_db_instance.application.master_user_secret[0].secret_arn
}

output "database_credentials_secret_status" {
  description = "Status of the RDS-managed master-user secret."
  value       = aws_db_instance.application.master_user_secret[0].secret_status
}
