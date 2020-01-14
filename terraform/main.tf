module "network" {
  source = "./modules/network"

  project     = "sinkholed"
  environment = var.environment
  tags        = local.tags
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
    cidr_blocks = concat(var.cidr_blocks, [module.network.cidr])
  }
  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = concat(var.cidr_blocks, [module.network.cidr])
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = concat(var.cidr_blocks, [module.network.cidr])
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = concat(var.cidr_blocks, [module.network.cidr])
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

module "cluster" {
  source = "./modules/cluster"

  project     = "sinkholed"
  environment = var.environment

  tags = local.tags
}

resource "random_password" "jwt_secret" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name_prefix = "sinkholed/${var.environment}/jwt_secret/"

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = random_password.jwt_secret.result

  lifecycle {
    ignore_changes = [
      secret_string
    ]
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

  tags = local.tags
}

module "autoscalinggroup" {
  source = "./modules/autoscalinggroup"

  project           = "sinkholed"
  environment       = var.environment
  securitygroup_id  = aws_security_group.clustersg.id
  min_size          = 1
  max_size          = 1
  ami               = data.aws_ami.latest_ecs.id
  instance_type     = "t2.micro"
  subnets           = module.network.public_subnets
  vpc_id            = module.network.vpc_id
  user_data         = data.template_file.user_data.rendered
  ec2_instance_key  = "sinkholed-${var.environment}"
  cloudwatch_prefix = "sinkholed-${var.environment}"

  tags = local.tags
}

module "service" {
  source = "./modules/service"

  project                            = "sinkholed"
  environment                        = var.environment
  name                               = "sinkholed-${var.environment}"
  vpc_id                             = module.network.vpc_id
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
  ecr_repository                     = data.aws_ecr_repository.service.arn
  container_log_group_name           = "/sinkholed-${var.environment}/service"
  subnets                            = module.network.public_subnets
  allow_security_groups              = [aws_security_group.clustersg.id]
  cloudwatch_prefix                  = "sinkholed-${var.environment}"

  container_port_mappings = [
    # {
    #   containerPort = 53
    #   hostPort      = 53
    #   protocol      = "udp"
    # },
    # {
    #   containerPort = 80
    #   hostPort      = 80
    #   protocol      = "tcp"
    # },
    # {
    #   containerPort = 443
    #   hostPort      = 443
    #   protocol      = "tcp"
    # },
    {
      containerPort = 1337
      hostPort      = 1337
      protocol      = "tcp"
    }
  ]

  container_environment = [
    {
      name  = "SINKHOLED_ES_ADDRESSES"
      value = "https://${module.elasticsearch.endpoint}"
    },
    {
      name  = "SINKHOLED_ES_AWS",
      value = true
    }
  ]

  container_secrets_configuration = [
    {
      name      = "SINKHOLED_JWTSECRET",
      valueFrom = aws_secretsmanager_secret.jwt_secret.id
    }
  ]

  tags = local.tags
}

resource "aws_iam_role_policy" "task_execution_role_policy" {
  name   = "sinkholed-${var.environment}-task-execution-role-policy-allow-secrets"
  role   = module.service.task_execution_role_arn
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "secretsmanager:GetSecretValue"
          ],
          "Resource": "${aws_secretsmanager_secret.jwt_secret.id}"
      }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name   = "sinkholed-${var.environment}-task-role-policy"
  role   = module.service.task_role_arn
  policy = <<EOF
{
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "es:*"
      ],
      "Resource": [
        "${module.elasticsearch.arn}/*"
      ]
    }
  ]
}
EOF
}

