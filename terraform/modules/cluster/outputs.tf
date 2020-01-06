output "cluster_name" {
  description = "Name of the cluster"
  value       = aws_ecs_cluster.cluster.name
}

output "iam_instance_role" {
  description = "IAM instance role created for the EC2 instances"
  value       = aws_ecs_cluster.cluster.name
}

