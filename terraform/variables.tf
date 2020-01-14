variable "tags" {
  type        = map(string)
  description = "Global list of tags to apply to all resources"
  default = {
    managedBy = "terraform"
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

