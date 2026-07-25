output "transfer_bucket_name" {
  description = "Name of the S3 bucket used for Ansible SSM file transfers."
  value       = aws_s3_bucket.ansible_transfer.id
}

output "transfer_bucket_arn" {
  description = "ARN of the S3 bucket used for Ansible SSM file transfers."
  value       = aws_s3_bucket.ansible_transfer.arn
}

output "database_secret_policy_name" {
  description = "Name of the inline IAM policy allowing database secret retrieval."
  value       = aws_iam_role_policy.database_secret_access.name
}
