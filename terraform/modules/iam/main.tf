locals {
  name_prefix = "${var.project_name}-${var.environment}"

  tags = merge(
    var.common_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Component   = "IAM"
    }
  )
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "AllowEC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "application" {
  name               = "${local.name_prefix}-application-role"
  description        = "IAM role used by private application EC2 instances."
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-application-role"
      Tier = "application"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.application.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "application" {
  name = "${local.name_prefix}-application-profile"
  role = aws_iam_role.application.name

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-application-profile"
      Tier = "application"
    }
  )
}
