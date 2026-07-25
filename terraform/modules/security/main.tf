locals {
  name_prefix = "${var.project_name}-${var.environment}"

  tags = merge(
    var.common_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Component   = "Security"
    }
  )
}

# ---------------------------------------------------------------------------
# Application Load Balancer security group
# ---------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Controls traffic reaching the application load balancer."
  vpc_id      = var.vpc_id

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-alb-sg"
      Tier = "load-balancer"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  description = "Allow public HTTP traffic."
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-alb-http-ingress"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  description = "Allow public HTTPS traffic."
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-alb-https-ingress"
    }
  )
}

# The load balancer can send traffic only to resources carrying the
# application security group, and only on the application port.
resource "aws_vpc_security_group_egress_rule" "alb_to_application" {
  security_group_id = aws_security_group.alb.id

  description                  = "Allow the ALB to reach application servers."
  referenced_security_group_id = aws_security_group.application.id
  from_port                    = var.application_port
  to_port                      = var.application_port
  ip_protocol                  = "tcp"

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-alb-to-application"
    }
  )
}

# ---------------------------------------------------------------------------
# Application security group
# ---------------------------------------------------------------------------

resource "aws_security_group" "application" {
  name        = "${local.name_prefix}-application-sg"
  description = "Controls traffic reaching the private application servers."
  vpc_id      = var.vpc_id

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-application-sg"
      Tier = "application"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "application_from_alb" {
  security_group_id = aws_security_group.application.id

  description                  = "Allow application traffic from the ALB."
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.application_port
  to_port                      = var.application_port
  ip_protocol                  = "tcp"

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-application-from-alb"
    }
  )
}

# Allows HTTPS access through the NAT Gateway for SSM, software repositories
# and other approved external services.
resource "aws_vpc_security_group_egress_rule" "application_https" {
  security_group_id = aws_security_group.application.id

  description = "Allow outbound HTTPS through the NAT Gateway."
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-application-https-egress"
    }
  )
}

# Some Linux package repositories still redirect or expose metadata over HTTP.
resource "aws_vpc_security_group_egress_rule" "application_http" {
  security_group_id = aws_security_group.application.id

  description = "Allow outbound HTTP through the NAT Gateway."
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-application-http-egress"
    }
  )
}

resource "aws_vpc_security_group_egress_rule" "application_to_database" {
  security_group_id = aws_security_group.application.id

  description                  = "Allow application servers to reach PostgreSQL."
  referenced_security_group_id = aws_security_group.database.id
  from_port                    = var.database_port
  to_port                      = var.database_port
  ip_protocol                  = "tcp"

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-application-to-database"
    }
  )
}

# ---------------------------------------------------------------------------
# Database security group
# ---------------------------------------------------------------------------

resource "aws_security_group" "database" {
  name        = "${local.name_prefix}-database-sg"
  description = "Controls traffic reaching the isolated database tier."
  vpc_id      = var.vpc_id

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-database-sg"
      Tier = "database"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "database_from_application" {
  security_group_id = aws_security_group.database.id

  description                  = "Allow PostgreSQL traffic from application servers."
  referenced_security_group_id = aws_security_group.application.id
  from_port                    = var.database_port
  to_port                      = var.database_port
  ip_protocol                  = "tcp"

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-database-from-application"
    }
  )
}
