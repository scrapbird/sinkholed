// ecs iam role and policies
resource "aws_iam_role" "ecs_role" {
  name               = "${var.project}-${var.environment}-ecs_role"
  assume_role_policy = file("${path.module}/policies/ecs-role-assume-policy.json")
}

// ec2 container instance role & policy
resource "aws_iam_role_policy" "ecs_instance_role_policy" {
  name = "${var.project}-${var.environment}-ecs_instance_role_policy"
  policy = templatefile("${path.module}/policies/ecs-instance-role-policy.json.tpl",
    {
      cloudwatch_prefix = var.cloudwatch_prefix
    }
  )
  role = aws_iam_role.ecs_role.id
}

// IAM profile to be used in auto-scaling launch configuration.
resource "aws_iam_instance_profile" "ecs" {
  name = "${var.project}-${var.environment}-ecs-instance-profile"
  path = "/"
  role = aws_iam_role.ecs_role.name
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project}-${var.environment}-task-execution-role"
  assume_role_policy = file("${path.module}/policies/ecs-task-execution-role-assume-policy.json")
}

resource "aws_iam_role_policy" "ecs_task_execution_role_policy" {
  name = "${var.project}-${var.environment}-task-execution-role-policy"
  policy = templatefile("${path.module}/policies/ecs-task-execution-role-policy.json.tpl",
    {
      cloudwatch_prefix = var.cloudwatch_prefix
      jwt_secret        = var.jwt_secret
      ecr_repo_arn      = var.ecr_repository
    }
  )
  role = aws_iam_role.ecs_task_execution_role.id
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.project}-${var.environment}-task-role"
  assume_role_policy = file("${path.module}/policies/ecs-task-execution-role-assume-policy.json")
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "${var.project}-${var.environment}-task-execution-role-policy"
  policy = templatefile("${path.module}/policies/ecs-task-role-policy.json.tpl",
    {
      elasticsearch_domain_arn = var.elasticsearch_domain_arn
    }
  )
  role = aws_iam_role.ecs_task_role.id
}
