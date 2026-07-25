variable "project_name" {
  description = "Name of the project used in resource naming and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment, such as dev, test or prod."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block assigned to the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "Availability Zones used by the networking module."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two Availability Zones must be supplied."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks assigned to the public subnets."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least two public subnet CIDR blocks must be supplied."
  }
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks assigned to the private application subnets."
  type        = list(string)

  validation {
    condition     = length(var.private_app_subnet_cidrs) >= 2
    error_message = "At least two private application subnet CIDR blocks must be supplied."
  }
}

variable "enable_nat_gateway" {
  description = "Whether to provision a NAT Gateway for private subnet internet access."
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags applied to networking resources."
  type        = map(string)
  default     = {}
}
