# Sinkholed AWS Configuration 

A collection of terraform templates that can be used to bring up a production ready implementation of sinkholed on AWS.

# Created Resources

This setup will create the following resources inside your AWS account:

- A VPC with internet gateway, subnets etc
- A SecretsManager secret to store the generated JWT secret key
- An elasticsearch cluster
- An ECS cluster
- An EC2 autoscaling group with accompanying launch configuration etc
- An ECS service to run sinkholed
- Accompanying IAM roles / EC2 security groups etc

# Usage

The terraform template can be run with all default values, although it is suggested to override the `cidr_blocks` variable. This specifies the CIDR blocks to allow access to the open ports in the sinkholed cluster.

Simply run `terraform init && terraform apply` to have a ready to use sinkholed environment created for you.
