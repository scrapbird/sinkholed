variable "name_prefix" {
  type        = string
  description = "String to prefix to all named resources created by the module"
}

variable "tags" {
  type        = map
  description = "Global list of tags to apply to all resources"
  default = {
    managedBy = "terraform"
  }
}

variable "min_size" {
  default     = 1
  description = "Min size of cluster autoscaling group"
}

variable "max_size" {
  default     = 1
  description = "Max size of cluster autoscaling group"
}

variable "ami" {
  type        = string
  description = "AMI to use for the EC2 instances"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type to use for EC2 instances"
}

variable "user_data" {
  type        = string
  description = "User data for the EC2 instance"
}

variable "subnets" {
  type        = list(string)
  description = "List of subnets to use for the autoscaling group"
}

variable "port_mappings" {
  description = "A list of ports to allow to connect to the autoscaling group instances"
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [{
    port        = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }]
}

variable "vpc_id" {
  description = "ID of the VPC to use"
}

variable "ec2_instance_key" {
  type        = string
  description = "The ssh key to use for the ec2 instances"
}

variable "cloudwatch_prefix" {
  type        = string
  description = "The prefix used for the CloudWatch LogGroup"
}

