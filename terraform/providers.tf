provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
     Environment = var.environment_name
     Project = "bkulek-bootcamp"
   }
 }
}

terraform {
  required_providers {
    aws = {
      version = ">= 5.26.0"
    }
  }

  required_version = ">= 1.6.0"
}