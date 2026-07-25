locals {
  name_prefix = "${var.project_name}-${var.environment}"

  tags = merge(
    var.common_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Component   = "Load Balancing"
    }
  )
}

resource "aws_lb" "application" {
  name               = "${local.name_prefix}-application-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [var.alb_security_group_id]
  subnets         = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = true

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-application-alb"
      Tier = "public"
    }
  )
}

resource "aws_lb_target_group" "application" {
  name = "${local.name_prefix}-application-tg"

  port        = var.application_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  deregistration_delay = 30

  health_check {
    enabled = true

    protocol = "HTTP"
    port     = "traffic-port"
    path     = var.health_check_path
    matcher  = "200-399"

    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-application-tg"
      Tier = "application"
    }
  )
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-http-listener"
      Tier = "public"
    }
  )
}

resource "aws_autoscaling_attachment" "application" {
  autoscaling_group_name = var.autoscaling_group_name
  lb_target_group_arn    = aws_lb_target_group.application.arn
}
