variable "aws_region" {
  description = "AWS region to create resources in"
  default     = "eu-central-1"
}


variable "vpc_id" {
  description = "VPC ID"
  default     = "vpc-e7ac8e8c"
}

variable "environment_name" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ttl" {
  description = "Time to live"
  type        = string
}

variable "template_type" {
  description = "Template type for ansible"
  type        = string
}
