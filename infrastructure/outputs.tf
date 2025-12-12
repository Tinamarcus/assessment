output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = module.vpc.private_subnet_id
}

output "mongodb_vm_public_ip" {
  description = "Public IP of MongoDB VM"
  value       = module.mongodb.public_ip
}

output "mongodb_vm_private_ip" {
  description = "Private IP of MongoDB VM"
  value       = module.mongodb.private_ip
}

output "mongodb_instance_id" {
  description = "Instance ID of MongoDB VM"
  value       = module.mongodb.instance_id
}

output "ssh_private_key" {
  description = "SSH private key for MongoDB VM access"
  value       = module.mongodb.ssh_private_key
  sensitive   = true
}

output "ssh_public_key" {
  description = "SSH public key"
  value       = module.mongodb.ssh_public_key
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "s3_bucket_name" {
  description = "S3 bucket name for MongoDB backups"
  value       = module.s3.bucket_id
}

output "ecr_repository_name" {
  description = "ECR repository name for application images"
  value       = module.ecr.repository_name
}

output "ecr_repository_url" {
  description = "ECR repository URL for application images"
  value       = module.ecr.repository_url
}

output "alb_dns_name" {
  description = "ALB DNS name (get from Kubernetes Ingress after deployment)"
  value       = "Run: kubectl get ingress tasky-ingress -n wiz-exercise -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "kubernetes_apply_command" {
  description = "Command to apply Kubernetes manifests"
  value       = "kubectl apply -f ../kubernetes/"
}
