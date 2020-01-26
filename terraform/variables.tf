variable "tags" {
  type        = map(string)
  description = "Global list of tags to apply to all resources"
  default = {
    ManagedBy = "terraform"
  }
}

variable "environment" {
  type        = string
  description = "The environment (dev, qa, prod etc)"
  default     = "production"
}

variable "cidr_blocks" {
  type        = list
  description = "The CIDR blocks to allow access to ports used by sinkholed. (Modify the main.tf for more fine grain control)"
  default     = ["0.0.0.0/0"]
}

variable "ecr_repository" {
  type        = string
  description = "The name of the ECR repository to deploy from"
  default     = "sinkholed"
}

variable "image_tag" {
  type        = string
  description = "The tagged image to deploy"
  default     = "latest"
}

# TODO : Implement this
variable "ssh_cidr_blocks" {
  type        = list
  description = "A list of CIDR blocks to allow SSH access to the cluster instances. If this is left as null no SSH access will be configured."
  default     = null
}

variable "ec2_instance_key" {
  type        = string
  description = "The SSH key to use to provide access to the autoscaling group instances"
}

variable "autoscaling_group_ports" {
  description = "The ports to open in the autoscaling group security group"
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [{
    port        = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }]
}

variable "container_port_mappings" {
  description = "Ports to map into the running containers"
  type = list(object({
    containerPort = number
    hostPort      = number
    protocol      = string
  }))

  default = [
    {
      containerPort = 1337
      hostPort      = 1337
      protocol      = "tcp"
    }
  ]
}
