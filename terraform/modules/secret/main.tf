resource "aws_secretsmanager_secret" "main" {
  name_prefix = var.name_prefix

  tags = var.tags
}

