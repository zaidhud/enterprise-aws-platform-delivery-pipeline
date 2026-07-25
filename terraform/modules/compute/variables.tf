variable "project_name" {
  description = "Name of the platform project."
  type        = string
}

variable "environment" {
  description = "Deployment environment such as dev, test, stage or prod."
  type        = string
}

variable "private_app_subnet_ids" {
  description = "Private application subnet IDs used by the Auto Scaling Group."
  type        = list(string)

  validation {
    condition     = length(var.private_app_subnet_ids) >= 2
    error_message = "At least two private application subnet IDs must be supplied."
  }
}

variable "application_security_group_id" {
  description = "Security group assigned to the application EC2 instances."
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile attached to the application EC2 instances."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type used by the application fleet."
  type        = string
  default     = "t3.micro"
}

variable "application_port" {
  description = "Port on which the bootstrap application listens."
  type        = number
  default     = 8080

  validation {
    condition     = var.application_port >= 1 && var.application_port <= 65535
    error_message = "The application port must be between 1 and 65535."
  }
}

variable "root_volume_size" {
  description = "Size of the encrypted root EBS volume in GiB."
  type        = number
  default     = 10

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "The root volume must be at least 8 GiB."
  }
}

variable "minimum_capacity" {
  description = "Minimum number of instances in the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "maximum_capacity" {
  description = "Maximum number of instances in the Auto Scaling Group."
  type        = number
  default     = 4
}

variable "health_check_grace_period" {
  description = "Seconds allowed for a new instance to become healthy."
  type        = number
  default     = 300
}

variable "common_tags" {
  description = "Common tags applied to compute resources."
  type        = map(string)
  default     = {}
}
