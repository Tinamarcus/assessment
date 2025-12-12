variable "mongodb_backup_bucket_arn" {
  description = "ARN of MongoDB backup S3 bucket"
  type        = string
}

variable "bucket_name_prefix" {
  description = "Prefix for S3 bucket names"
  type        = string
}

# Removed eks_security_group_id and mongodb_security_group_id variables
# Security group rules are handled by the respective modules

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "wiz-exercise"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
