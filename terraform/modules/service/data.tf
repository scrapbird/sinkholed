data "aws_region" "current" {}

data "aws_subnet" "subnets" {
  count = length(var.subnets)
  id    = var.subnets[count.index]
}

data "null_data_source" "task_container_port_mappings" {
  count = length(var.container_port_mappings)

  inputs = {
    hostPort      = var.container_port_mappings[count.index].containerPort
    containerPort = var.container_port_mappings[count.index].containerPort
    protocol      = var.container_port_mappings[count.index].protocol
  }
}

