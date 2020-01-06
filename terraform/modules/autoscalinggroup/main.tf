resource "aws_launch_configuration" "main" {
  name            = "${var.project}-${var.environment}"
  instance_type   = var.instance_type
  image_id        = var.ami // TODO Check this
  security_groups = [var.securitygroup_id]
  user_data       = var.user_data
}

resource "aws_autoscaling_group" "main" {
  name                 = "${var.project}-${var.environment}-asg"
  launch_configuration = aws_launch_configuration.main.id
  min_size             = var.min_size
  max_size             = var.max_size
  vpc_zone_identifier  = var.subnets

  # tags = [data.null_data_source.asg_tags.*.outputs]
  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

