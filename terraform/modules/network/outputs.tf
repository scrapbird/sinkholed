output "vpc_id" {
  description = "ID of the network VPC"
  value       = aws_vpc.vpc.id
}

output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = aws_internet_gateway.gateway.id
}

output "private_subnets" {
  description = "A list of the private subnets."
  value       = aws_subnet.private.*.id
}

output "public_subnets" {
  description = "A list of the private subnets."
  value       = aws_subnet.public.*.id
}

