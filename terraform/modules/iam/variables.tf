variable "project_name" {
  description = "Name of the platform project."
  type        = string
}

variable "environment" {
  description = "Deployment environment such as dev, test, stage or prod."
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
