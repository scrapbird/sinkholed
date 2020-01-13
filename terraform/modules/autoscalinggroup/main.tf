// ec2 container instance role & policy
resource "aws_iam_role" "ecs_instance_role" {
  name               = "${var.project}-${var.environment}-ecs-instance-role"
  assume_role_policy = file("${path.module}/policies/ecs-role-assume-policy.json")

  tags = var.tags
}
resource "aws_iam_role_policy" "ecs_instance_role_policy" {
  name = "${var.project}-${var.environment}-ecs-instance-role-policy"
  policy = templatefile("${path.module}/policies/ecs-instance-role-policy.json.tpl",
    {
      cloudwatch_prefix = var.cloudwatch_prefix
    }
  )
  role = aws_iam_role.ecs_instance_role.id
}

// IAM profile to be used in auto-scaling launch configuration.
resource "aws_iam_instance_profile" "ecs" {
  name = "${var.project}-${var.environment}-ecs-instance-profile"
  path = "/"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_launch_configuration" "main" {
  name_prefix          = "${var.project}-${var.environment}"
  instance_type        = var.instance_type
  image_id             = var.ami
  security_groups      = [var.securitygroup_id]
  user_data            = var.user_data
  iam_instance_profile = aws_iam_instance_profile.ecs.id
  key_name             = var.ec2_instance_key

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "main" {
  name                 = "${var.project}-${var.environment}-asg"
  launch_configuration = aws_launch_configuration.main.id
  min_size             = var.min_size
  max_size             = var.max_size
  vpc_zone_identifier  = var.subnets

  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

