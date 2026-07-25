output "launch_template_id" {
  description = "ID of the application EC2 launch template."
  value       = aws_launch_template.application.id
}

output "launch_template_name" {
  description = "Name of the application EC2 launch template."
  value       = aws_launch_template.application.name
}

output "autoscaling_group_name" {
  description = "Name of the application Auto Scaling Group."
  value       = aws_autoscaling_group.application.name
}

output "autoscaling_group_arn" {
  description = "ARN of the application Auto Scaling Group."
  value       = aws_autoscaling_group.application.arn
}

output "amazon_linux_2023_ami_id" {
  description = "Amazon Linux 2023 AMI selected through the AWS public parameter."
  value       = data.aws_ssm_parameter.amazon_linux_2023_ami.value
}
