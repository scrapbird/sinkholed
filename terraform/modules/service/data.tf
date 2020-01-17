data "aws_region" "current" {}

data "aws_subnet" "subnets" {
  count = length(var.subnets)
  id    = var.subnets[count.index]
}

