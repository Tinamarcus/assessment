resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "mongodb_backups" {
  bucket = "${var.bucket_name}-${random_id.bucket_suffix.hex}"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-mongodb-backups"
  })
}

# Public read access (intentional security weakness)
resource "aws_s3_bucket_public_access_block" "mongodb_backups" {
  bucket = aws_s3_bucket.mongodb_backups.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "mongodb_backups" {
  bucket = aws_s3_bucket.mongodb_backups.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "mongodb_backups" {
  bucket = aws_s3_bucket.mongodb_backups.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PublicReadGetObject"
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.mongodb_backups.arn}/*"
      },
      {
        Sid    = "PublicListBucket"
        Effect = "Allow"
        Principal = "*"
        Action = "s3:ListBucket"
        Resource = aws_s3_bucket.mongodb_backups.arn
      }
    ]
  })
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
