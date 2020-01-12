variable "project" {
  type        = string
  description = "The project name"
}

variable "environment" {
  type        = string
  description = "The project environment (dev, qa, prod etc)"
}

variable "cloudwatch_prefix" {
  type        = string
  description = "The prefix used for the CloudWatch LogGroup"
}

variable "jwt_secret" {
  type        = string
  description = "The ARN of the secrets manager secret used to store the JWT"
}

variable "ecr_repository" {
  type        = string
  description = "The ARN of the ecr repository to use for deployments"
}

variable "elasticsearch_domain_arn" {
  type        = string
  description = "The ARN of the elasticsearch domain"
}

variable "tags" {
  type        = map
  description = "Global list of tags to apply to all resources"
  default = {
    managedBy = "terraform"
  }
}
