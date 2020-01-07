resource "aws_ecs_task_definition" "main" {
  family             = var.task_definition_family
  execution_role_arn = var.execution_role_arn
  container_definitions = replace(jsonencode([
    {
      name             = var.name
      image            = var.image_url
      cpu              = var.cpu
      memory           = var.memory
      essential        = var.essential
      portMappings     = var.container_port_mappings
      logConfiguration = local.container_log_configuration
      secrets          = var.container_secrets_configuration
    }
  ]), "/\"([0-9]+\\.?[0-9]*)\"/", "$1")
}

resource "aws_cloudwatch_log_group" "service_log_group" {
  name = var.container_log_group
  tags = var.tags
}

resource "aws_ecs_service" "main" {
  name            = var.name
  desired_count   = var.desired_count
  task_definition = aws_ecs_task_definition.main.id
  cluster         = var.cluster

  # Need to opt in to new ARN format to use tags on services
  # https://aws.amazon.com/blogs/compute/migrating-your-amazon-ecs-deployment-to-the-new-arn-and-resource-id-format-2/
  # tags = var.tags
}

