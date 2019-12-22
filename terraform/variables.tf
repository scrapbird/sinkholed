variable "tags" {
  type = map(string)
  description = "Global list of tags to apply to all resources"
  default = {
    managedBy = "terraform"
  } 
}

variable "project" {
  type = string
  description = "The project name"
}

variable "environment" {
  type = string
  description = "The project environment (dev, qa, prod etc)"
}

