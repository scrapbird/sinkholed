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
}

variable "cidr_blocks" {
  type        = list
  description = "The CIDR blocks to allow access to ports used by sinkholed. (Modify the main.tf for more fine grain control)"
  default     = ["0.0.0.0/0"]
}

variable "image_url" {
  type        = string
  description = "The URL to the docker build to run (ECR)"
}
