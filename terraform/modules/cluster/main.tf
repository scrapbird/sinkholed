resource "aws_ecs_cluster" "cluster" {
  name = "${var.project}-${var.environment}-cluster"

  tags = var.tags
}

