resource "aws_secretsmanager_secret" "main" {
  name = var.name

  tags = var.tags
}

