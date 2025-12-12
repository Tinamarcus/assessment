output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (multi-AZ)"
  value       = [aws_subnet.private.id, aws_subnet.private_2.id]
}

output "public_subnet_cidr" {
  description = "Public subnet CIDR block"
  value       = aws_subnet.public.cidr_block
}

output "private_subnet_cidr" {
  description = "Private subnet CIDR block"
  value       = aws_subnet.private.cidr_block
}

output "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks (multi-AZ)"
  value       = [aws_subnet.private.cidr_block, aws_subnet.private_2.cidr_block]
}
