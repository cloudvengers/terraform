# Terraform 설정 블록
terraform {                                                        # Terraform 블록 시작
  required_providers {                                             # 필수 프로바이더 정의
    aws = {                                                        # AWS 프로바이더 설정
      source  = "hashicorp/aws"                                    # 프로바이더 소스 (HashiCorp 공식)
      version = "~> 6.0"                                           # 프로바이더 버전 (6.x 최신)
    }
  }
}

# AWS 프로바이더 설정
provider "aws" {                                                   # AWS 프로바이더 블록
  region = "us-east-1"                                             # AWS 리전 (버지니아 북부)
  
  # 모든 리소스에 자동으로 적용될 기본 태그
  default_tags {                                                   # 기본 태그 블록
    tags = {                                                       # 태그 맵
      environment = "Test"                                         # 환경 태그
      Owner       = "Ki"                                           # 소유자 태그
    }
  }
}
