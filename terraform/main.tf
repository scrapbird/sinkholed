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
    cidr_blocks = var.cidr_blocks
  }
  ingress {
    from_port   = 2525
    to_port     = 2525
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.cidr_blocks
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

module "service" {
  source                 = "./modules/service"
  project                = "sinkholed"
  environment            = var.environment
  name                   = "sinkholed-${var.environment}"
  cluster                = module.cluster.cluster_name
  max_count              = 1
  min_count              = 1
  desired_count          = 1
  task_definition_family = "sinkholed"
  cpu                    = 512
  memory                 = 128
  image_url              = var.image_url

  container_port_mappings = [
    {
      containerPort = 53
      hostPort      = 53
      protocol      = "udp"
    },
    {
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    },
    {
      containerPort = 443
      hostPort      = 443
      protocol      = "tcp"
    },
    {
      containerPort = 2525
      hostPort      = 2525
      protocol      = "tcp"
    }
  ]

  tags = {
    managedBy   = "terraform"
    environment = var.environment
    project     = "sinkholed"
  }
}

