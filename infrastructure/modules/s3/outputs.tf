output "bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.mongodb_backups.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.mongodb_backups.arn
}
