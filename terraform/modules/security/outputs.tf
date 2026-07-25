output "alb_security_group_id" {
  description = "ID of the Application Load Balancer security group."
  value       = aws_security_group.alb.id
}

output "application_security_group_id" {
  description = "ID of the private application security group."
  value       = aws_security_group.application.id
}

output "database_security_group_id" {
  description = "ID of the isolated database security group."
  value       = aws_security_group.database.id
}
