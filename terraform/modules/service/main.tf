resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project}-${var.environment}-task-execution-role"
  assume_role_policy = file("${path.module}/policies/ecs-task-role-assume-policy.json")
}

resource "aws_iam_role_policy" "ecs_task_execution_role_policy" {
  name = "${var.project}-${var.environment}-task-execution-role-policy"
  policy = templatefile("${path.module}/policies/ecs-task-execution-role-policy.json.tpl",
    {
      ecr_repo_arn      = var.ecr_repository
      cloudwatch_prefix = var.cloudwatch_prefix
    }
  )
  role = aws_iam_role.ecs_task_execution_role.id
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.project}-${var.environment}-task-role"
  assume_role_policy = file("${path.module}/policies/ecs-task-role-assume-policy.json")
}

resource "aws_ecs_task_definition" "main" {
  family             = var.task_definition_family
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn
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
      environment      = var.container_environment
    }
  ]), "/\"([0-9]+\\.?[0-9]*)\"/", "$1")

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "service_log_group" {
  name = var.container_log_group_name
  tags = var.tags
}

resource "aws_lb" "main" {
  name                             = "${var.project}-${var.environment}-lb"
  internal                         = false
  load_balancer_type               = "network"
  subnets                          = var.subnets
  enable_cross_zone_load_balancing = true

  enable_deletion_protection = true

  tags = var.tags
}

resource "aws_lb_target_group" "main" {
  count = length(var.container_port_mappings)

  name        = "${var.project}-${var.environment}-target-${count.index}"
  port        = var.container_port_mappings[count.index].hostPort
  protocol    = upper(var.container_port_mappings[count.index].protocol)
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    interval            = 10
    port                = var.container_port_mappings[count.index].hostPort
    protocol            = upper(var.container_port_mappings[count.index].protocol)
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = var.tags
}

resource "aws_lb_listener" "main" {
  count = length(var.container_port_mappings)

  load_balancer_arn = aws_lb.main.arn
  port              = var.container_port_mappings[count.index].hostPort
  protocol          = upper(var.container_port_mappings[count.index].protocol)

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[count.index].arn
  }

  depends_on = [aws_lb_target_group.main]
}

resource "aws_ecs_service" "main" {
  name                               = var.name
  desired_count                      = var.desired_count
  task_definition                    = aws_ecs_task_definition.main.id
  cluster                            = var.cluster
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  dynamic "load_balancer" {
    for_each = aws_lb_target_group.main
    iterator = target_group

    content {
      target_group_arn = target_group.value.id
      container_name   = var.name
      container_port   = target_group.value.port
    }
  }

  # Need to opt in to new ARN format to use tags on services
  # https://aws.amazon.com/blogs/compute/migrating-your-amazon-ecs-deployment-to-the-new-arn-and-resource-id-format-2/
  # tags = var.tags
}

