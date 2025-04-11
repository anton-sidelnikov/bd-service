terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.94.1"
    }
  }
  backend "s3" {
    bucket         = "bds-tf-state" // need to be created before (ex. state-bootstrap.tf)
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks" // need to be created before (ex. state-bootstrap.tf)
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
