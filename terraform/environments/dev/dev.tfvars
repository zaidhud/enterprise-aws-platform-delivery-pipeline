aws_region   = "eu-west-2"
project_name = "eapdp"
environment  = "dev"

vpc_cidr = "10.20.0.0/16"

public_subnet_cidrs = [
  "10.20.0.0/24",
  "10.20.1.0/24"
]

private_app_subnet_cidrs = [
  "10.20.10.0/24",
  "10.20.11.0/24"
]

enable_nat_gateway = true

private_db_subnet_cidrs = [
  "10.20.20.0/24",
  "10.20.21.0/24"
]
