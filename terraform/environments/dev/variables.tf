variable "aws_region" {
  description = "AWS Region used for the development environment."
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Project name used in resource names and tags."
  type        = string
  default     = "eapdp"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block assigned to the development VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks assigned to development public subnets."
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks assigned to development private application subnets."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether the development environment provisions a NAT Gateway."
  type        = bool
  default     = true
}
