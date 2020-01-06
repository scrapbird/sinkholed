variable "project" {
  type        = string
  description = "The project name"
}

variable "environment" {
  type        = string
  description = "The project environment (dev, qa, prod etc)"
}

variable "tags" {
  type        = map
  description = "Global list of tags to apply to all resources"
  default = {
    managedBy = "terraform"
  }
}

variable "securitygroup_id" {
  description = "Security group ID to use for the ASG instances"
}

variable "min_size" {
  description = "Min size of cluster autoscaling group"
}

variable "max_size" {
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

variable "vpc_id" {
  description = "ID of the VPC to use"
}

variable "iam_instance_profile" {
  type        = string
  description = "IAM instance profile ID to use for the launch configuration"
}

variable "ec2_instance_key" {
  type        = string
  description = "The ssh key to use for the ec2 instances"
}

