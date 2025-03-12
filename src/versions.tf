terraform {
  required_version = "~> 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.35"
    }
  }

  # backend "s3" {
  #   // TODO ADD backend here
  # }
}

provider "aws" {
  region = local.aws_region

  default_tags {
    tags = {
      Team        = "Smart"
      Managed-By  = "Terraform"
      Application = "API Gateway v2 / Lambda example"
    }
  }
}

#-------------------------------------#

locals {
  env                  = terraform.workspace
  resource_name_prefix = "apig-v2-lambda-example"
  aws_region           = "eu-central-1"
}
