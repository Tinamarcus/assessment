resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "mongodb_backups" {
  bucket = "${var.bucket_name}-${random_id.bucket_suffix.hex}"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-mongodb-backups"
  })
}

resource "aws_s3_bucket_public_access_block" "mongodb_backups" {
  bucket = aws_s3_bucket.mongodb_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "mongodb_backups" {
  bucket = aws_s3_bucket.mongodb_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption enabled for security controls requirement
resource "aws_s3_bucket_server_side_encryption_configuration" "mongodb_backups" {
  bucket = aws_s3_bucket.mongodb_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}