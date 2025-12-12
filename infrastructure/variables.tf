variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-2"
}

variable "bucket_name" {
  description = "Base name for S3 backup bucket"
  type        = string
  default     = "wiz-mongodb-backups"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "wiz-exercise-cluster"
}

variable "ecr_repository_name" {
  description = "ECR repository name for the application image"
  type        = string
  default     = "tasky"
}

variable "container_image" {
  description = "Container image for the application (CI/CD will update this in the generated manifest)."
  type        = string
  default     = "REPLACE_ME_IN_CI"
}

