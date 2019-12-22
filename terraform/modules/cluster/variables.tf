variable "project" {
  type = string
  description = "The project name"
}

variable "environment" {
  type = string
  description = "The project environment (dev, qa, prod etc)"
}

variable "tags" {
  type = map
  description = "Global list of tags to apply to all resources"
  default = {
    managedBy = "terraform"
  } 
}

variable "min_size" {
  description = "Min size of cluster autoscaling group"
}

variable "max_size" {
  description = "Max size of cluster autoscaling group"
}

variable "desired_size" {
  description = "Desired size of cluster autoscaling group"
}

variable "ami" {
  type = string
  description = "AMI to use for the EC2 instances"
}

variable "instance_type" {
  type = string
  description = "EC2 instance type to use for EC2 instances"
}

variable "subnets" {
  description = "List of subnets to use for the autoscalin group"
}

