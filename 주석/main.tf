# ============================================
# Terraform 설정 블록
# Terraform이 동작하기 위해 필요한 기본 설정을 정의하는 블록입니다.
# 어떤 클라우드(AWS, GCP 등)를 사용할지, 어떤 버전을 쓸지 여기서 결정합니다.
# ============================================
terraform {                          # terraform {} 블록: Terraform 자체의 동작 방식을 설정합니다
  required_providers {               # required_providers: 이 프로젝트에서 사용할 클라우드 제공자(프로바이더) 목록입니다
    aws = {                          # aws: AWS(Amazon Web Services)를 프로바이더로 사용하겠다는 선언입니다
      source  = "hashicorp/aws"      # source: AWS 프로바이더의 출처입니다. HashiCorp(Terraform 제작사)가 공식 제공하는 AWS 플러그인을 사용합니다
      version = "~> 6.0"             # version: 사용할 프로바이더 버전입니다. "~> 6.0"은 6.0 이상 7.0 미만의 최신 버전을 자동으로 사용한다는 뜻입니다
    }
  }
}

# ============================================
# AWS 프로바이더 설정
# AWS에 접속할 때 사용할 리전(지역)과 기본 태그를 설정합니다.
# 태그는 AWS 리소스에 이름표를 붙이는 것과 같아서, 나중에 리소스를 구분하고 관리하는 데 유용합니다.
# ============================================
provider "aws" {                     # provider "aws": AWS 클라우드에 연결하기 위한 설정 블록입니다
  region = "us-east-1"               # region: AWS 리소스를 생성할 지역입니다. "us-east-1"은 미국 동부(버지니아) 리전으로, 가장 많이 사용되는 리전입니다
  default_tags {                     # default_tags: 이 프로바이더로 생성하는 모든 AWS 리소스에 자동으로 붙는 기본 태그입니다
    tags = {                         # tags: 태그 목록을 정의합니다. 태그는 "키 = 값" 형태의 라벨입니다
      Environment = "Test"           # Environment 태그: 이 리소스가 테스트 환경용임을 표시합니다 (예: Test, Dev, Production 등으로 구분)
      Owner       = "Ki"             # Owner 태그: 이 리소스의 소유자/담당자가 "Ki"임을 표시합니다. 비용 추적이나 책임 소재 파악에 유용합니다
    }
  }
}
