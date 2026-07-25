variable "project_name" {
  description = "Name of the platform project."
  type        = string
}

variable "environment" {
  description = "Deployment environment such as dev, test, stage or prod."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the security groups will be created."
  type        = string
}

variable "application_port" {
  description = "TCP port exposed by the application servers."
  type        = number
  default     = 8080

  validation {
    condition = (
      var.application_port >= 1 &&
      var.application_port <= 65535
    )

    error_message = "The application port must be between 1 and 65535."
  }
}

variable "database_port" {
  description = "TCP port exposed by the PostgreSQL database."
  type        = number
  default     = 5432

  validation {
    condition = (
      var.database_port >= 1 &&
      var.database_port <= 65535
    )

    error_message = "The database port must be between 1 and 65535."
  }
}

variable "common_tags" {
  description = "Common tags applied to all security resources."
  type        = map(string)
  default     = {}
}
