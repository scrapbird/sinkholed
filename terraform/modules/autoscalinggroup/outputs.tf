output "security_group_id" {
  description = "The ID of the security group attached to the instances"
  value       = aws_security_group.main.id
}
