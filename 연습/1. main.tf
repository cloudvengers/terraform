# Terraform 설정 블록
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}


# AWS 프로바이더 설정
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      environment = "Test"
      Owner       = "Ki"
    }
  }
}
