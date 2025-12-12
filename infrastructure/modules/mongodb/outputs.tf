output "instance_id" {
  description = "MongoDB instance ID"
  value       = aws_instance.mongodb.id
}

output "public_ip" {
  description = "Public IP of MongoDB instance"
  value       = aws_instance.mongodb.public_ip
}

output "private_ip" {
  description = "Private IP of MongoDB instance"
  value       = aws_instance.mongodb.private_ip
}

output "security_group_id" {
  description = "Security group ID for MongoDB VM"
  value       = aws_security_group.mongodb_vm.id
}

output "ssh_private_key" {
  description = "SSH private key for MongoDB VM access"
  value       = tls_private_key.main.private_key_pem
  sensitive   = true
}

output "ssh_public_key" {
  description = "SSH public key"
  value       = tls_private_key.main.public_key_openssh
}

output "key_name" {
  description = "AWS key pair name"
  value       = aws_key_pair.main.key_name
}
