output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.codebuild.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "security_group_id" {
  description = "ID of the CodeBuild security group"
  value       = aws_security_group.codebuild.id
}