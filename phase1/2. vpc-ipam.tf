# =====================================================
# IPAM
# =====================================================

data "aws_region" "current" {}                                     # 현재 프로바이더의 리전 정보를 가져오는 데이터 소스
data "aws_caller_identity" "current" {}                            # 현재 AWS 계정 정보를 가져오는 데이터 소스

# IPAM (IP Address Manager) 생성
resource "aws_vpc_ipam" "main" {                                   # IPAM 리소스 정의 (IP 주소 중앙 관리)
  operating_regions {                                              # 운영 리전 블록
    region_name = data.aws_region.current.region                   # 현재 리전에서 IPAM 운영
  }
}

# 부모 IPAM Pool 생성
resource "aws_vpc_ipam_pool" "main" {                              # 부모 IPAM Pool 리소스 정의
  address_family = "ipv4"                                          # IP 주소 체계 (IPv4)
  ipam_scope_id  = aws_vpc_ipam.main.private_default_scope_id     # IPAM의 Private Scope ID (자동 생성됨)
  locale         = data.aws_region.current.region                  # Pool이 사용될 리전
}

# 부모 Pool에 CIDR 블록 할당
resource "aws_vpc_ipam_pool_cidr" "main" {                         # 부모 Pool CIDR 리소스 정의
  ipam_pool_id = aws_vpc_ipam_pool.main.id                         # 대상 IPAM Pool ID
  cidr         = "10.0.0.0/8"                                      # Pool에 할당할 전체 CIDR 대역
}

# =====================================================
# VPC
# =====================================================

resource "aws_vpc" "main" {                                        # VPC 리소스 정의
  ipv4_ipam_pool_id   = aws_vpc_ipam_pool.main.id                  # CIDR을 할당받을 부모 IPAM Pool ID
  ipv4_netmask_length = 16                                         # IPAM에서 할당받을 CIDR 크기 (/16)
  depends_on          = [aws_vpc_ipam_pool_cidr.main]              # 부모 Pool에 CIDR이 먼저 할당되어야 함
}

# =====================================================
# VPC용 자식 IPAM Pool (서브넷 CIDR 자동 할당용)
# =====================================================

resource "aws_vpc_ipam_pool" "vpc" {                               # VPC 리소스 플래닝용 자식 IPAM Pool 정의
  address_family      = "ipv4"                                     # IP 주소 체계 (IPv4)
  ipam_scope_id       = aws_vpc_ipam.main.private_default_scope_id # IPAM의 Private Scope ID
  locale              = data.aws_region.current.region             # Pool이 사용될 리전
  source_ipam_pool_id = aws_vpc_ipam_pool.main.id                  # 부모 Pool ID (계층 구조)

  source_resource {                                                # 이 Pool이 관리할 소스 리소스 정의
    resource_id     = aws_vpc.main.id                              # 대상 VPC ID
    resource_owner  = data.aws_caller_identity.current.account_id  # VPC 소유 AWS 계정 ID
    resource_region = data.aws_region.current.region               # VPC가 위치한 리전
    resource_type   = "vpc"                                        # 리소스 유형 (VPC)
  }
}

resource "aws_vpc_ipam_pool_cidr" "vpc" {                          # 자식 Pool CIDR 리소스 정의
  ipam_pool_id = aws_vpc_ipam_pool.vpc.id                          # 대상 자식 IPAM Pool ID
  cidr         = aws_vpc.main.cidr_block                           # VPC에 할당된 CIDR을 자식 Pool에 등록
}

# =====================================================
# Internet Gateway
# =====================================================

resource "aws_internet_gateway" "igw" {                            # Internet Gateway 리소스 정의
  vpc_id = aws_vpc.main.id                                         # 연결할 VPC ID

  tags = {                                                         # 태그 맵
    Name = "igw"                                                   # Internet Gateway 이름
  }
}

# =====================================================
# Public Subnets (인터넷 게이트웨이 연결)
# =====================================================

resource "aws_subnet" "public_a" {                                 # Public Subnet A 리소스 정의
  vpc_id              = aws_vpc.main.id                            # VPC ID
  ipv4_ipam_pool_id   = aws_vpc_ipam_pool.vpc.id                  # 서브넷 CIDR을 할당받을 자식 IPAM Pool ID
  ipv4_netmask_length = 24                                         # IPAM에서 할당받을 서브넷 크기 (/24)
  availability_zone   = "us-east-1a"                               # 가용 영역 A
  depends_on          = [aws_vpc_ipam_pool_cidr.vpc]               # 자식 Pool에 CIDR이 먼저 할당되어야 함

  tags = {                                                         # 태그 맵
    Name = "public-subnet-a"                                       # 서브넷 이름
  }
}

resource "aws_subnet" "public_c" {                                 # Public Subnet C 리소스 정의
  vpc_id              = aws_vpc.main.id                            # VPC ID
  ipv4_ipam_pool_id   = aws_vpc_ipam_pool.vpc.id                  # 서브넷 CIDR을 할당받을 자식 IPAM Pool ID
  ipv4_netmask_length = 24                                         # IPAM에서 할당받을 서브넷 크기 (/24)
  availability_zone   = "us-east-1c"                               # 가용 영역 C
  depends_on          = [aws_vpc_ipam_pool_cidr.vpc]               # 자식 Pool에 CIDR이 먼저 할당되어야 함

  tags = {                                                         # 태그 맵
    Name = "public-subnet-c"                                       # 서브넷 이름
  }
}

# =====================================================
# Private App Subnets (애플리케이션 계층)
# =====================================================

resource "aws_subnet" "private_app_a" {                            # Private App Subnet A 리소스 정의
  vpc_id              = aws_vpc.main.id                            # VPC ID
  ipv4_ipam_pool_id   = aws_vpc_ipam_pool.vpc.id                  # 서브넷 CIDR을 할당받을 자식 IPAM Pool ID
  ipv4_netmask_length = 24                                         # IPAM에서 할당받을 서브넷 크기 (/24)
  availability_zone   = "us-east-1a"                               # 가용 영역 A
  depends_on          = [aws_vpc_ipam_pool_cidr.vpc]               # 자식 Pool에 CIDR이 먼저 할당되어야 함

  tags = {                                                         # 태그 맵
    Name = "private-app-subnet-a"                                  # 서브넷 이름
  }
}

resource "aws_subnet" "private_app_c" {                            # Private App Subnet C 리소스 정의
  vpc_id              = aws_vpc.main.id                            # VPC ID
  ipv4_ipam_pool_id   = aws_vpc_ipam_pool.vpc.id                  # 서브넷 CIDR을 할당받을 자식 IPAM Pool ID
  ipv4_netmask_length = 24                                         # IPAM에서 할당받을 서브넷 크기 (/24)
  availability_zone   = "us-east-1c"                               # 가용 영역 C
  depends_on          = [aws_vpc_ipam_pool_cidr.vpc]               # 자식 Pool에 CIDR이 먼저 할당되어야 함

  tags = {                                                         # 태그 맵
    Name = "private-app-subnet-c"                                  # 서브넷 이름
  }
}

# =====================================================
# Private DB Subnets (데이터베이스 계층)
# =====================================================

resource "aws_subnet" "private_db_a" {                             # Private DB Subnet A 리소스 정의
  vpc_id              = aws_vpc.main.id                            # VPC ID
  ipv4_ipam_pool_id   = aws_vpc_ipam_pool.vpc.id                  # 서브넷 CIDR을 할당받을 자식 IPAM Pool ID
  ipv4_netmask_length = 24                                         # IPAM에서 할당받을 서브넷 크기 (/24)
  availability_zone   = "us-east-1a"                               # 가용 영역 A
  depends_on          = [aws_vpc_ipam_pool_cidr.vpc]               # 자식 Pool에 CIDR이 먼저 할당되어야 함

  tags = {                                                         # 태그 맵
    Name = "private-db-subnet-a"                                   # 서브넷 이름
  }
}

resource "aws_subnet" "private_db_c" {                             # Private DB Subnet C 리소스 정의
  vpc_id              = aws_vpc.main.id                            # VPC ID
  ipv4_ipam_pool_id   = aws_vpc_ipam_pool.vpc.id                  # 서브넷 CIDR을 할당받을 자식 IPAM Pool ID
  ipv4_netmask_length = 24                                         # IPAM에서 할당받을 서브넷 크기 (/24)
  availability_zone   = "us-east-1c"                               # 가용 영역 C
  depends_on          = [aws_vpc_ipam_pool_cidr.vpc]               # 자식 Pool에 CIDR이 먼저 할당되어야 함

  tags = {                                                         # 태그 맵
    Name = "private-db-subnet-c"                                   # 서브넷 이름
  }
}
