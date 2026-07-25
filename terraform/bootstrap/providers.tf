provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "bootstrap"
      ManagedBy   = "Terraform"
      Owner       = "Platform Engineering"
      Repository  = var.github_repository
    }
  }
}
