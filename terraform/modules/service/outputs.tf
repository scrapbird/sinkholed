output "lb_endpoint" {
  description = "The endpoint that can be used to connect to the load balancer"
  value       = aws_lb.main.dns_name
}

output "task_execution_role_arn" {
  description = "The ARN of the created ecs task execution role"
  value       = aws_iam_role.ecs_task_execution_role.id
}

output "task_role_arn" {
  description = "The ARN of the created ecs task role"
  value       = aws_iam_role.ecs_task_role.id
}
