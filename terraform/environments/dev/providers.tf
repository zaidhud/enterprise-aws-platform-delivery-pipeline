provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Platform Engineering"
      Repository  = "zaidhud/enterprise-aws-platform-delivery-pipeline"
    }
  }
}
