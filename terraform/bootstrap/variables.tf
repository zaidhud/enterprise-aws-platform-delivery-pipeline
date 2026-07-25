variable "aws_region" {
  description = "AWS region used for the platform."
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Name applied to project resources."
  type        = string
  default     = "enterprise-aws-platform-delivery-pipeline"
}

variable "github_repository" {
  description = "GitHub repository in owner/repository format."
  type        = string
}

variable "terraform_state_bucket_name" {
  description = "Globally unique S3 bucket used for Terraform state."
  type        = string

  validation {
    condition = (
      length(var.terraform_state_bucket_name) >= 3 &&
      length(var.terraform_state_bucket_name) <= 63
    )

    error_message = "The S3 bucket name must contain between 3 and 63 characters."
  }
}
