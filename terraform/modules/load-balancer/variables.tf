variable "project_name" {
  description = "Name of the platform project."
  type        = string
}

variable "environment" {
  description = "Deployment environment such as dev, test, stage or prod."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC in which the target group is created."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs used by the internet-facing load balancer."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least two public subnet IDs must be supplied."
  }
}

variable "alb_security_group_id" {
  description = "Security group assigned to the Application Load Balancer."
  type        = string
}

variable "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group attached to the target group."
  type        = string
}

variable "application_port" {
  description = "Port on which the application instances receive traffic."
  type        = number
  default     = 8080

  validation {
    condition     = var.application_port >= 1 && var.application_port <= 65535
    error_message = "The application port must be between 1 and 65535."
  }
}

variable "health_check_path" {
  description = "HTTP path used to verify application health."
  type        = string
  default     = "/"

  validation {
    condition     = startswith(var.health_check_path, "/")
    error_message = "The health-check path must begin with a forward slash."
  }
}

variable "enable_deletion_protection" {
  description = "Whether deletion protection is enabled on the load balancer."
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags applied to load-balancing resources."
  type        = map(string)
  default     = {}
}
