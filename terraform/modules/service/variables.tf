variable "tags" {
  type        = map
  description = "Global list of tags to apply to all resources"
  default = {
    ManagedBy = "terraform"
  }
}

variable "name_prefix" {
  type        = string
  description = "Name prefix to use for all resources created for the service"
}

variable "cluster" {
  type        = string
  description = "The name of the cluster to use"
}

variable "task_definition_family" {
  type        = string
  description = "Family name to use for the created task definition"
}

variable "container_port_mappings" {
  type = list(object({
    containerPort = number
    protocol      = string
  }))
}

variable "container_environment" {
  type = list(object({
    name  = string
    value = string
  }))
}

variable "container_secrets_configuration" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
}

variable "desired_count" {
  description = "Desired count of tasks to run"
}

variable "max_count" {
  description = "Max count of tasks to run"
}

variable "min_count" {
  description = "Min count of tasks to run"
}

variable "deployment_minimum_healthy_percent" {
  description = "Min healthy percent configuration for ECS service. If only running 1 task at maximum cluster capacity set this to 0."
  default     = 0
}

variable "deployment_maximum_percent" {
  description = "Maximum percent usage of cluster to use as an upper limit for deployments. If running cluster as maximum capacity set this to 100"
  default     = 100
}

variable "image_url" {
  type        = string
  description = "The URL to the docker build to run"
}

variable "cpu" {
  type        = string
  description = "CPU units to assign to the service"
}

variable "memory" {
  type        = string
  description = "MB of memory to assign to the service"
}

variable "essential" {
  type        = bool
  description = "Whether or not to mark the service as essential"
  default     = true
}

variable "container_log_group_name" {
  type        = string
  description = "Log group to use for the service container logs"
}

variable "subnets" {
  type        = list(string)
  description = "List of subnet IDs to use for the load balancer group"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC the service will reside in"
}

variable "security_group_id" {
  type        = string
  description = "The ID of the security group to add incoming traffic rules to to allow local subnet access to the service ports. This is to allow the load balancer health checks access to the service."
}

variable "ecr_repository" {
  type        = string
  description = "The ARN of the ecr repository to use for deployments"
}

variable "cloudwatch_prefix" {
  type        = string
  description = "The prefix used for the CloudWatch LogGroup"
}

