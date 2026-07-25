data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  availability_zones = slice(
    data.aws_availability_zones.available.names,
    0,
    2
  )
}

module "networking" {
  source = "../../modules/networking"

  project_name             = var.project_name
  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = local.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  enable_nat_gateway       = var.enable_nat_gateway

  common_tags = {
    Component = "Networking"
  }
}


module "security" {
  source = "../../modules/security"

  project_name     = var.project_name
  environment      = var.environment
  vpc_id           = module.networking.vpc_id
  application_port = var.application_port
  database_port    = var.database_port

  common_tags = {
    Owner = "Platform Engineering"
  }
}

module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment

  common_tags = {
    Owner = "Platform Engineering"
  }
}

module "compute" {
  source = "../../modules/compute"

  project_name = var.project_name
  environment  = var.environment

  private_app_subnet_ids        = module.networking.private_app_subnet_ids
  application_security_group_id = module.security.application_security_group_id
  instance_profile_name         = module.iam.application_instance_profile_name

  common_tags = {
    Owner = "Platform Engineering"
  }
}
module "load_balancer" {
  source = "../../modules/load-balancer"

  project_name = var.project_name
  environment  = var.environment

  vpc_id                 = module.networking.vpc_id
  public_subnet_ids      = module.networking.public_subnet_ids
  alb_security_group_id  = module.security.alb_security_group_id
  autoscaling_group_name = module.compute.autoscaling_group_name

  application_port           = 8080
  health_check_path          = "/"
  enable_deletion_protection = false

  common_tags = {
    Owner = "Platform Engineering"
  }
}

module "database" {
  source = "../../modules/database"

  project_name               = var.project_name
  environment                = var.environment
  private_db_subnet_ids      = module.networking.private_db_subnet_ids
  database_security_group_id = module.security.database_security_group_id

  database_name   = "platformdb"
  master_username = "platformadmin"

  engine_version          = "16"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp3"
  storage_encrypted       = true
  multi_az                = false
  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true
  apply_immediately       = false

  performance_insights_enabled = true
  monitoring_interval          = 0

  tags = {
    CostCentre = "Platform Engineering"
  }
}

module "ansible_support" {
  source = "../../modules/ansible-support"

  project_name          = var.project_name
  environment           = var.environment
  application_role_name = module.iam.application_role_name
  database_secret_arn   = module.database.database_credentials_secret_arn

  transfer_object_expiration_days = 1

  tags = {
    CostCentre = "Platform Engineering"
  }
}
