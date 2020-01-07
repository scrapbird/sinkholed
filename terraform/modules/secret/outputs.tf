output "secret_arn" {
  description = "The ARN of the created secret"
  value       = aws_secretsmanager_secret.main.id
}
