resource "aws_cloudtrail" "main" {
  name           = "${var.name_prefix}-cloudtrail"
  s3_bucket_name = aws_s3_bucket.cloudtrail.id

  include_global_service_events = true
  is_multi_region_trail         = true

  event_selector {
    read_write_type                 = "All"
    include_management_events      = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${var.mongodb_backup_bucket_arn}/*"]
    }
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-cloudtrail"
    }
  )
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket = "${var.bucket_name_prefix}-cloudtrail-${random_id.cloudtrail_suffix.hex}"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-cloudtrail"
    }
  )
}

resource "random_id" "cloudtrail_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-guardduty"
    }
  )
}

# Note: Security group rules for EKS to MongoDB are not needed here because:
# - EKS security group already allows all egress (0.0.0.0/0)
# - MongoDB security group already allows ingress from private subnet CIDR
# The existing rules are sufficient for connectivity.
