locals {
  tags = merge(var.tags, {
    environment = var.environment
    project     = "sinkholed"
    managedBy   = "terraform"
  })
}

module "network" {
  source = "./modules/network"

  project     = "sinkholed"
  environment = var.environment
  tags        = local.tags
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

  name_prefix       = "sinkholed-${var.environment}"
  min_size          = 1
  max_size          = 1
  ami               = data.aws_ami.latest_ecs.id
  instance_type     = "t2.micro"
  subnets           = module.network.public_subnets
  vpc_id            = module.network.vpc_id
  user_data         = data.template_file.user_data.rendered
  ec2_instance_key  = "sinkholed-test"
  cloudwatch_prefix = "sinkholed-${var.environment}"

  ports = [{
    port        = 1337
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks
  }]

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
  security_group_id                  = module.autoscalinggroup.security_group_id
  cloudwatch_prefix                  = "sinkholed-${var.environment}"
  container_port_mappings            = var.container_port_mappings

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

