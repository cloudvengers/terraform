# 현재 AWS 리전 정보 조회
data "aws_region" "current" {}                                     # 현재 프로바이더의 리전 정보를 가져오는 데이터 소스

# IPAM (IP Address Manager) 생성
resource "aws_vpc_ipam" "main" {                                   # IPAM 리소스 정의 (IP 주소 중앙 관리)
  
  # IPAM이 작동할 리전 설정
  operating_regions {                                              # 운영 리전 블록
    region_name = data.aws_region.current.region                   # 현재 리전에서 IPAM 운영
  }
}

# IPAM Pool 생성
resource "aws_vpc_ipam_pool" "main" {                              # IPAM Pool 리소스 정의
  address_family = "ipv4"                                          # IP 주소 체계 (IPv4)
  ipam_scope_id = aws_vpc_ipam.main.private_default_scope_id      # IPAM의 Private Scope ID (자동 생성됨)
  locale = data.aws_region.current.region                          # Pool이 사용될 리전
}

# IPAM Pool에 CIDR 블록 할당
resource "aws_vpc_ipam_pool_cidr" "main" {                         # IPAM Pool CIDR 리소스 정의
  ipam_pool_id = aws_vpc_ipam_pool.main.id                         # 대상 IPAM Pool ID
  cidr = "10.0.0.0/8"                                              # Pool에 할당할 CIDR 대역
}

# VPC 생성 (IPAM에서 자동 할당)
resource "aws_vpc" "main" {                                        # VPC 리소스 정의
  ipv4_ipam_pool_id = aws_vpc_ipam_pool.main.id                    # CIDR을 할당받을 IPAM Pool ID
  ipv4_netmask_length = 16                                         # 할당받을 CIDR 크기 (/16)
  depends_on = [aws_vpc_ipam_pool_cidr.main]                       # Pool에 CIDR이 먼저 할당되어야 함
}

# =====================================================
# Public Subnets (인터넷 게이트웨이 연결)
# =====================================================

# Public Subnet A (가용 영역 A)
resource "aws_subnet" "public_a" {                                 # Public Subnet 리소스 정의
  vpc_id = aws_vpc.main.id                                         # VPC ID
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 1)          # VPC CIDR에서 /24 서브넷 생성 (.1.0/24)
  availability_zone = "us-east-1a"                                 # 가용 영역 A

  tags = {                                                         # 태그 맵
    Name = "public-subnet-a"                                       # 서브넷 이름
  }
}

# Public Subnet C (가용 영역 C)
resource "aws_subnet" "public_c" {                                 # Public Subnet 리소스 정의
  vpc_id = aws_vpc.main.id                                         # VPC ID
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 2)          # VPC CIDR에서 /24 서브넷 생성 (.2.0/24)
  availability_zone = "us-east-1c"                                 # 가용 영역 C

  tags = {                                                         # 태그 맵
    Name = "public-subnet-c"                                       # 서브넷 이름
  }
}

# =====================================================
# Private App Subnets (애플리케이션 계층)
# =====================================================

# Private App Subnet A (가용 영역 A)
resource "aws_subnet" "private_app_a" {                            # Private App Subnet 리소스 정의
  vpc_id = aws_vpc.main.id                                         # VPC ID
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 11)         # VPC CIDR에서 /24 서브넷 생성 (.11.0/24)
  availability_zone = "us-east-1a"                                 # 가용 영역 A

  tags = {                                                         # 태그 맵
    Name = "private-app-subnet-a"                                  # 서브넷 이름
  }
}

# Private App Subnet C (가용 영역 C)
resource "aws_subnet" "private_app_c" {                            # Private App Subnet 리소스 정의
  vpc_id = aws_vpc.main.id                                         # VPC ID
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 12)         # VPC CIDR에서 /24 서브넷 생성 (.12.0/24)
  availability_zone = "us-east-1c"                                 # 가용 영역 C

  tags = {                                                         # 태그 맵
    Name = "private-app-subnet-c"                                  # 서브넷 이름
  }
}

# =====================================================
# Private DB Subnets (데이터베이스 계층)
# =====================================================

# Private DB Subnet A (가용 영역 A)
resource "aws_subnet" "private_db_a" {                             # Private DB Subnet 리소스 정의
  vpc_id = aws_vpc.main.id                                         # VPC ID
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 21)         # VPC CIDR에서 /24 서브넷 생성 (.21.0/24)
  availability_zone = "us-east-1a"                                 # 가용 영역 A

  tags = {                                                         # 태그 맵
    Name = "private-db-subnet-a"                                   # 서브넷 이름
  }
}

# Private DB Subnet C (가용 영역 C)
resource "aws_subnet" "private_db_c" {                             # Private DB Subnet 리소스 정의
  vpc_id = aws_vpc.main.id                                         # VPC ID
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 22)         # VPC CIDR에서 /24 서브넷 생성 (.22.0/24)
  availability_zone = "us-east-1c"                                 # 가용 영역 C

  tags = {                                                         # 태그 맵
    Name = "private-db-subnet-c"                                   # 서브넷 이름
  }
}
