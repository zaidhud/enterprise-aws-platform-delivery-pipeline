data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  transfer_bucket_name = lower(
    "${local.name_prefix}-ansible-ssm-${data.aws_caller_identity.current.account_id}"
  )

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Platform Engineering"
      Component   = "Ansible"
    },
    var.tags
  )
}

resource "aws_s3_bucket" "ansible_transfer" {
  bucket = local.transfer_bucket_name

  force_destroy = true

  tags = merge(
    local.common_tags,
    {
      Name    = local.transfer_bucket_name
      Purpose = "Ansible SSM temporary file transfer"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "ansible_transfer" {
  bucket = aws_s3_bucket.ansible_transfer.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "ansible_transfer" {
  bucket = aws_s3_bucket.ansible_transfer.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ansible_transfer" {
  bucket = aws_s3_bucket.ansible_transfer.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "ansible_transfer" {
  bucket = aws_s3_bucket.ansible_transfer.id

  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ansible_transfer" {
  bucket = aws_s3_bucket.ansible_transfer.id

  rule {
    id     = "expire-temporary-ansible-files"
    status = "Enabled"

    filter {}

    expiration {
      days = var.transfer_object_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.ansible_transfer
  ]
}

data "aws_iam_policy_document" "database_secret_access" {
  statement {
    sid    = "ReadApplicationDatabaseSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      var.database_secret_arn
    ]
  }
}

resource "aws_iam_role_policy" "database_secret_access" {
  name   = "${local.name_prefix}-database-secret-access"
  role   = var.application_role_name
  policy = data.aws_iam_policy_document.database_secret_access.json
}
