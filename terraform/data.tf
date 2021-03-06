data "aws_ami" "latest_ecs" {
  most_recent = true
  owners      = ["591542846629"] # AWS

  filter {
    name   = "name"
    values = ["*amazon-ecs-optimized"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user_data.sh")}"

  vars = {
    cluster_name      = aws_ecs_cluster.cluster.name
    cloudwatch_prefix = "/sinkholed-${var.environment}"
  }
}

data "aws_ecr_repository" "service" {
  name = var.ecr_repository
}

