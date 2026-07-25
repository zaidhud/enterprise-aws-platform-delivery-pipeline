variable "project_name" {
  description = "Project name used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "application_role_name" {
  description = "Name of the IAM role attached to application EC2 instances."
  type        = string
}

variable "database_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager secret."
  type        = string
}

variable "transfer_object_expiration_days" {
  description = "Number of days before temporary Ansible transfer objects expire."
  type        = number
  default     = 1

  validation {
    condition     = var.transfer_object_expiration_days >= 1
    error_message = "The transfer object expiration period must be at least one day."
  }
}

variable "tags" {
  description = "Additional tags applied to resources."
  type        = map(string)
  default     = {}
}
