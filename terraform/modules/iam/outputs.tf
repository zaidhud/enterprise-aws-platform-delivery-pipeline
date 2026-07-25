output "application_role_name" {
  description = "Name of the IAM role used by application EC2 instances."
  value       = aws_iam_role.application.name
}

output "application_role_arn" {
  description = "ARN of the IAM role used by application EC2 instances."
  value       = aws_iam_role.application.arn
}

output "application_instance_profile_name" {
  description = "Name of the application EC2 instance profile."
  value       = aws_iam_instance_profile.application.name
}

output "application_instance_profile_arn" {
  description = "ARN of the application EC2 instance profile."
  value       = aws_iam_instance_profile.application.arn
}
