output "ecs_instance_profile_id" {
  description = "Instance profile for the EC2 instance"
  value       = aws_iam_instance_profile.ecs.id
}

# output "ecs_execution_role_arn" {
#   description = "ARN for the ecs execution role"
#   value       = aws_iam_role.ecs_task_execution_role.arn
# }

# output "ecs_task_role_arn" {
#   description = "ARN for the ecs task role"
#   value       = aws_iam_role.ecs_task_role.arn
# }
