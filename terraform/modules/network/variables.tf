variable "project" {
  type = string
  description = "The project name"
}

variable "tags" {
  type = map
  description = "Global list of tags to apply to all resources"
  default = {
    managedBy = "terraform"
  } 
}

variable "cidr" {
  description = "CIDR of the VPC"
  type = string
  default = "10.0.0.0/16"
}

variable "subnet_count" {
  description = "How many public and private subnet pairs to create"
  default = 2
}

