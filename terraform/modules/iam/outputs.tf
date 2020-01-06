output "ecs_instance_profile_id" {
  description = "Instance profile for the EC2 instance"
  value       = aws_iam_instance_profile.ecs.id
}
