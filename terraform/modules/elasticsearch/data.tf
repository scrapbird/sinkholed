data "aws_vpc" "selected" {
  id = var.vpc
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

