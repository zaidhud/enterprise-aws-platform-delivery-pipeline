locals {
  name_prefix = "${var.project_name}-${var.environment}"

  public_subnets = {
    for index, cidr in var.public_subnet_cidrs :
    index => {
      cidr              = cidr
      availability_zone = var.availability_zones[index]
    }
  }

  private_app_subnets = {
    for index, cidr in var.private_app_subnet_cidrs :
    index => {
      cidr              = cidr
      availability_zone = var.availability_zones[index]
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.common_tags,
    {
      Name = "${local.name_prefix}-vpc"
    }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name = "${local.name_prefix}-igw"
    }
  )
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false

  tags = merge(
    var.common_tags,
    {
      Name = "${local.name_prefix}-public-${each.value.availability_zone}"
      Tier = "public"
    }
  )
}

resource "aws_subnet" "private_app" {
  for_each = local.private_app_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false

  tags = merge(
    var.common_tags,
    {
      Name = "${local.name_prefix}-private-app-${each.value.availability_zone}"
      Tier = "private-application"
    }
  )
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name = "${local.name_prefix}-nat-eip"
    }
  )
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [
    aws_internet_gateway.main
  ]

  tags = merge(
    var.common_tags,
    {
      Name = "${local.name_prefix}-nat"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${local.name_prefix}-public-rt"
      Tier = "public"
    }
  )
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${local.name_prefix}-private-app-rt"
      Tier = "private-application"
    }
  )
}

resource "aws_route_table_association" "private_app" {
  for_each = aws_subnet.private_app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app.id
}

locals {
  private_db_subnets = {
    for index, cidr in var.private_db_subnet_cidrs :
    index => {
      cidr              = cidr
      availability_zone = var.availability_zones[index]
    }
  }
}

resource "aws_subnet" "private_db" {
  for_each = local.private_db_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false

  tags = merge(
    var.common_tags,
    {
      Name = "${local.name_prefix}-private-db-${each.value.availability_zone}"
      Tier = "private-database"
    }
  )
}

resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name = "${local.name_prefix}-private-db-rt"
      Tier = "private-database"
    }
  )
}

resource "aws_route_table_association" "private_db" {
  for_each = aws_subnet.private_db

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_db.id
}
