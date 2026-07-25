output "load_balancer_id" {
  description = "ID of the Application Load Balancer."
  value       = aws_lb.application.id
}

output "load_balancer_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.application.arn
}

output "load_balancer_dns_name" {
  description = "Public DNS name of the Application Load Balancer."
  value       = aws_lb.application.dns_name
}

output "load_balancer_zone_id" {
  description = "Canonical hosted-zone ID of the Application Load Balancer."
  value       = aws_lb.application.zone_id
}

output "target_group_arn" {
  description = "ARN of the application target group."
  value       = aws_lb_target_group.application.arn
}

output "target_group_name" {
  description = "Name of the application target group."
  value       = aws_lb_target_group.application.name
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener."
  value       = aws_lb_listener.http.arn
}
