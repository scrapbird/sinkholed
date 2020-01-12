variable "name_prefix" {
  type        = string
  description = "The name prefix of the secret"
}

variable "tags" {
  type        = map
  description = "Global list of tags to apply to all resources"
  default = {
    managedBy = "terraform"
  }
}

