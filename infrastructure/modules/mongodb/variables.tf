variable "vpc_id" {
  description = "VPC ID where MongoDB instance will be deployed"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for MongoDB instance"
  type        = string
}

variable "private_subnet_cidr" {
  description = "Private subnet CIDR for security group rule"
  type        = string
}

variable "backup_bucket_name" {
  description = "S3 bucket name for MongoDB backups"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for MongoDB"
  type        = string
  default     = "t3.medium"
}

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
