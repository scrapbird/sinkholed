variable "tags" {
  type = map(string)
  description = "Global list of tags to apply to all resources"
  default = {
    managedBy = "terraform"
  } 
}

variable "environment" {
  type = string
  description = "The environment (dev, qa, prod etc)"
}

