variable "project_name" {
  description = "Name of the platform project."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the deployment role."
  type        = string
}

variable "github_branch" {
  description = "GitHub branch allowed to assume the deployment role."
  type        = string
  default     = "main"
}

variable "aws_region" {
  description = "AWS Region used by the delivery pipeline."
  type        = string
}

variable "terraform_state_bucket_name" {
  description = "S3 bucket containing the Terraform remote state."
  type        = string
}

variable "terraform_state_key" {
  description = "S3 object key containing the Terraform state."
  type        = string
}

variable "ansible_transfer_bucket_name" {
  description = "S3 bucket used by Ansible for temporary SSM file transfers."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to CI/CD resources."
  type        = map(string)
  default     = {}
}
