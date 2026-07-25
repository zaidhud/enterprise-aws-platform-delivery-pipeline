locals {
  name_prefix = "${var.project_name}-${var.environment}"

  tags = merge(
    var.common_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Component   = "Compute"
    }
  )
}

data "aws_ssm_parameter" "amazon_linux_2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_launch_template" "application" {
  name_prefix   = "${local.name_prefix}-application-"
  description   = "Launch template for the private application fleet."
  image_id      = data.aws_ssm_parameter.amazon_linux_2023_ami.value
  instance_type = var.instance_type

  update_default_version = true

  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    device_index                = 0
    security_groups             = [var.application_security_group_id]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
    }
  }

  user_data = base64encode(
    templatefile(
      "${path.module}/templates/user-data.sh.tftpl",
      {
        environment      = var.environment
        application_port = var.application_port
      }
    )
  )

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.tags,
      {
        Name = "${local.name_prefix}-application"
        Tier = "application"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      local.tags,
      {
        Name = "${local.name_prefix}-application-root"
        Tier = "application"
      }
    )
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-application-launch-template"
      Tier = "application"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "application" {
  name = "${local.name_prefix}-application-asg"

  min_size         = var.minimum_capacity
  desired_capacity = var.desired_capacity
  max_size         = var.maximum_capacity

  health_check_type         = "EC2"
  health_check_grace_period = var.health_check_grace_period

  vpc_zone_identifier = var.private_app_subnet_ids

  launch_template {
    id      = aws_launch_template.application.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = var.health_check_grace_period
    }

    triggers = ["tag"]
  }

  dynamic "tag" {
    for_each = merge(
      local.tags,
      {
        Name = "${local.name_prefix}-application"
        Tier = "application"
      }
    )

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true

    precondition {
      condition = (
        var.minimum_capacity <= var.desired_capacity &&
        var.desired_capacity <= var.maximum_capacity
      )

      error_message = "Capacity must satisfy minimum <= desired <= maximum."
    }
  }
}
