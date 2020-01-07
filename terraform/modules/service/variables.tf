variable "project" {
  type        = string
  description = "The project name"
}

variable "environment" {
  type        = string
  description = "The project environment (dev, qa, prod etc)"
}

variable "tags" {
  type        = map
  description = "Global list of tags to apply to all resources"
  default = {
    managedBy = "terraform"
  }
}

variable "name" {
  type        = string
  description = "Name for the service"
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
    hostPort      = number
    containerPort = number
    protocol      = string
  }))
}

variable "container_secrets_configuration" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
}

variable "execution_role_arn" {
  type        = string
  description = "ARN for the ecs execution role"
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

variable "container_log_group" {
  type        = string
  description = "Log group to use for the service container logs"
}

