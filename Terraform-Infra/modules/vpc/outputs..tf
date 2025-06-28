output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value = [
    for k, subnet in aws_subnet.subnets : subnet.id 
      if can(regex("public", k))
  ]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value = [
    for k, subnet in aws_subnet.subnets : subnet.id 
      if can(regex("private", k))
  ]
}
