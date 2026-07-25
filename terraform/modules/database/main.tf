locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Platform Engineering"
      Component   = "Database"
      Tier        = "database"
    },
    var.tags
  )
}

resource "aws_db_subnet_group" "application" {
  name       = "${local.name_prefix}-database-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-database-subnet-group"
    }
  )
}

resource "aws_db_parameter_group" "application" {
  name   = "${local.name_prefix}-postgres16"
  family = "postgres16"

  parameter {
    name         = "log_connections"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_disconnections"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_min_duration_statement"
    value        = "1000"
    apply_method = "immediate"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-postgres16"
    }
  )
}

resource "aws_db_instance" "application" {
  identifier = "${local.name_prefix}-postgresql"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name                     = var.database_name
  username                    = var.master_username
  manage_master_user_password = true
  port                        = 5432

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted

  db_subnet_group_name   = aws_db_subnet_group.application.name
  vpc_security_group_ids = [var.database_security_group_id]
  parameter_group_name   = aws_db_parameter_group.application.name

  publicly_accessible = false
  multi_az            = var.multi_az

  backup_retention_period = var.backup_retention_period
  backup_window           = "02:00-03:00"
  maintenance_window      = "sun:03:00-sun:04:00"

  auto_minor_version_upgrade = true
  apply_immediately          = var.apply_immediately

  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name_prefix}-postgresql-final"

  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval          = var.monitoring_interval

  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "upgrade"
  ]

  copy_tags_to_snapshot = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-postgresql"
    }
  )
}
