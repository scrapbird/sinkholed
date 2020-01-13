locals {
  container_log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group  = var.container_log_group_name
      awslogs-region = data.aws_region.current.name
    }
  }
}
