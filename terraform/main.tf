module "network" {
  source      = "./modules/network"
  project     = "sinkholed"
  environment = var.environment
  tags = {
    managedBy   = "terraform"
    environment = var.environment
    project     = "sinkholed"
  }
}

resource "aws_security_group" "clustersg" {
  name        = "sinkholed-${var.environment}-cluster-sg"
  description = "Allow incoming traffic to the sinkholed-${var.environment} cluster instances."
  vpc_id      = module.network.vpc_id
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    managedBy   = "terraform"
    environment = var.environment
    project     = "sinkholed"
  }
}

module "cluster" {
  source      = "./modules/cluster"
  project     = "sinkholed"
  environment = var.environment

  tags = {
    managedBy   = "terraform"
    environment = var.environment
    project     = "sinkholed"
  }
}

module "iam_policies" {
  source = "./modules/iam"
}

module "autoscalinggroup" {
  source               = "./modules/autoscalinggroup"
  project              = "sinkholed"
  environment          = var.environment
  securitygroup_id     = aws_security_group.clustersg.id
  min_size             = 1
  max_size             = 1
  ami                  = data.aws_ami.latest_ecs.id
  instance_type        = "t2.micro"
  subnets              = module.network.public_subnets
  vpc_id               = module.network.vpc_id
  user_data            = data.template_file.user_data.rendered
  iam_instance_profile = module.iam_policies.ecs_instance_profile_id
  ec2_instance_key     = "sinkholed-${var.environment}"

  tags = {
    managedBy   = "terraform"
    environment = var.environment
    project     = "sinkholed"
  }
}

