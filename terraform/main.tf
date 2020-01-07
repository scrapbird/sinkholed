module "network" {
  source = "./modules/network"

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
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks
  }
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = var.cidr_blocks
  }
  ingress {
    from_port   = 1337
    to_port     = 1337
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
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    managedBy   = "terraform"
    environment = var.environment
    project     = "sinkholed"
  }
}

module "cluster" {
  source = "./modules/cluster"

  project     = "sinkholed"
  environment = var.environment

  tags = {
    managedBy   = "terraform"
    environment = var.environment
    project     = "sinkholed"
  }
}

module "jwt_secret" {
  source = "./modules/secret"

  name = "sinkholed/${var.environment}/jwt_secret"

  tags = {
    managedBy   = "terraform"
    environment = var.environment
    project     = "sinkholed"
  }
}

module "elasticsearch" {
  source = "./modules/elasticsearch"

  vpc    = module.network.vpc_id
  domain = "sinkholed-${var.environment}"

  # Can only use 1 subnet because 1 node
  subnet_ids            = [module.network.private_subnets[0]]
  instance_type         = "t2.small.elasticsearch"
  instance_count        = 1
  volume_type           = "gp2"
  volume_size           = 30
  elasticsearch_version = "6.7"
}

module "iam_policies" {
  source = "./modules/iam"

  project                  = "sinkholed"
  environment              = var.environment
  cloudwatch_prefix        = "sinkholed-${var.environment}"
  jwt_secret               = module.jwt_secret.arn
  ecr_repository           = data.aws_ecr_repository.service.arn
  elasticsearch_domain_arn = module.elasticsearch.arn

  tags = {
    managedBy   = "terraform"
    environment = var.environment
    project     = "sinkholed"
  }
}

module "autoscalinggroup" {
  source = "./modules/autoscalinggroup"

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
  source = "./modules/service"

  project                            = "sinkholed"
  environment                        = var.environment
  name                               = "sinkholed-${var.environment}"
  cluster                            = module.cluster.cluster_name
  max_count                          = 1
  min_count                          = 1
  desired_count                      = 1
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
  task_definition_family             = "sinkholed"
  cpu                                = 512
  memory                             = 128
  image_url                          = format("%s:%s", data.aws_ecr_repository.service.repository_url, var.image_tag)
  container_log_group                = "/sinkholed-${var.environment}/service"
  execution_role_arn                 = module.iam_policies.ecs_execution_role_arn
  task_role_arn                      = module.iam_policies.ecs_task_role_arn

  container_environment = [{
    name  = "SINKHOLED_ES_ADDRESSES"
    value = "https://${module.elasticsearch.endpoint}"
  }]

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
      containerPort = 1337
      hostPort      = 1337
      protocol      = "tcp"
    }
  ]

  container_secrets_configuration = [
    {
      name      = "SINKHOLED_JWT_SECRET",
      valueFrom = module.jwt_secret.arn
    }
  ]

  tags = {
    managedBy   = "terraform"
    environment = var.environment
    project     = "sinkholed"
  }
}

