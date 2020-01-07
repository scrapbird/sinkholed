variable "vpc" {}

variable "tags" {
  type        = map
  description = "Global list of tags to apply to all resources"
  default = {
    managedBy = "terraform"
  }
}

variable "domain" {
  type        = string
  description = "Name of the elasticsearch domain to create"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet ids to use for the domain"
}

variable "instance_type" {
  type        = string
  description = "The instance type to use"
  default     = "t2.small.elasticsearch"
}


variable "instance_count" {
  type        = number
  description = "The number of instances in the cluster"
  default     = 1
}

variable "volume_size" {
  type        = number
  description = "The size of the EBS volume for each instance"
  default     = 20
}

variable "volume_type" {
  type        = string
  description = "The type of EBS volume for each instance"
  default     = "gp2"
}

variable "elasticsearch_version" {
  type        = string
  description = "The version of elasticsearch to use"
  default     = "6.7.1"
}
