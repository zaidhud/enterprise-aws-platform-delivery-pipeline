variable "project_name" {
  description = "Name of the project."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "private_db_subnet_ids" {
  description = "Private subnet IDs used by the RDS subnet group."
  type        = list(string)

  validation {
    condition     = length(var.private_db_subnet_ids) >= 2
    error_message = "At least two private database subnet IDs must be provided."
  }
}

variable "database_security_group_id" {
  description = "Security group attached to the RDS instance."
  type        = string
}

variable "database_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "platformdb"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]*$", var.database_name))
    error_message = "The database name must begin with a letter and contain only letters, numbers and underscores."
  }
}

variable "master_username" {
  description = "Master username for the PostgreSQL database."
  type        = string
  default     = "platformadmin"
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16"
}

variable "instance_class" {
  description = "RDS database instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Initial allocated database storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage autoscaling limit in GiB."
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "RDS storage type."
  type        = string
  default     = "gp3"
}

variable "storage_encrypted" {
  description = "Whether RDS storage encryption is enabled."
  type        = bool
  default     = true
}

variable "multi_az" {
  description = "Whether to deploy a Multi-AZ database."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days automated backups are retained."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Whether deletion protection is enabled."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when deleting the database."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Whether database modifications are applied immediately."
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Whether Performance Insights is enabled."
  type        = bool
  default     = true
}

variable "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds. Use zero to disable it."
  type        = number
  default     = 0

  validation {
    condition = contains(
      [0, 1, 5, 10, 15, 30, 60],
      var.monitoring_interval
    )

    error_message = "Monitoring interval must be one of 0, 1, 5, 10, 15, 30 or 60."
  }
}

variable "tags" {
  description = "Additional tags applied to database resources."
  type        = map(string)
  default     = {}
}
