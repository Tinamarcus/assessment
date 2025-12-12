terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket  = "your-terraform-state-bucket"
    key     = "wiz-exercise/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Project   = "wiz-exercise"
    ManagedBy = "terraform"
  }
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  cluster_name        = var.cluster_name
  name_prefix         = "wiz-exercise"
  tags                = local.common_tags
}

module "s3" {
  source = "./modules/s3"

  bucket_name = var.bucket_name
  name_prefix = "wiz-exercise"
  tags        = local.common_tags
}

module "ecr" {
  source = "./modules/ecr"

  repository_name = var.ecr_repository_name
  tags            = local.common_tags
}

module "mongodb" {
  source = "./modules/mongodb"

  vpc_id              = module.vpc.vpc_id
  public_subnet_id    = module.vpc.public_subnet_id
  private_subnet_cidr = module.vpc.private_subnet_cidr
  backup_bucket_name  = module.s3.bucket_id
  instance_type       = "t3.medium"
  name_prefix         = "wiz-exercise"
  tags                = local.common_tags

  depends_on = [module.vpc, module.s3]
}

module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  kubernetes_version = "1.28"
  name_prefix        = "wiz-exercise"
  tags               = local.common_tags
}

module "security" {
  source = "./modules/security"

  mongodb_backup_bucket_arn = module.s3.bucket_arn
  bucket_name_prefix        = var.bucket_name
  name_prefix               = "wiz-exercise"
  tags                      = local.common_tags

  depends_on = [module.s3]
}
