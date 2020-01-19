// ec2 container instance role & policy
resource "aws_iam_role" "main" {
  name               = "${var.name_prefix}-instance-role"
  assume_role_policy = file("${path.module}/policies/role-assume-policy.json")

  tags = var.tags
}

resource "aws_iam_role_policy" "instance_role_policy" {
  name = "${var.name_prefix}-instance-role-policy"
  policy = templatefile("${path.module}/policies/instance-role-policy.json.tpl",
    {
      cloudwatch_prefix = var.cloudwatch_prefix
    }
  )
  role = aws_iam_role.main.id
}

// IAM profile to be used in auto-scaling launch configuration.
resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.name_prefix}-instance-profile"
  path = "/"
  role = aws_iam_role.main.name
}

resource "aws_security_group" "main" {
  name        = "${var.name_prefix}-autoscaling-sg"
  description = "Allow incoming traffic to the ${var.name_prefix} autoscaling instances."
  vpc_id      = var.vpc_id

  dynamic ingress {
    for_each = var.port_mappings
    iterator = mapping
    content {
      from_port   = mapping.value.port
      to_port     = mapping.value.port
      protocol    = mapping.value.protocol
      cidr_blocks = mapping.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_launch_configuration" "main" {
  name_prefix          = var.name_prefix
  instance_type        = var.instance_type
  image_id             = var.ami
  security_groups      = [aws_security_group.main.id]
  user_data            = var.user_data
  iam_instance_profile = aws_iam_instance_profile.instance_profile.id
  key_name             = var.ec2_instance_key

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "main" {
  name                 = "${var.name_prefix}-asg"
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

