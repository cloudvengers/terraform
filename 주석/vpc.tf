# ============================================
# VPC(Virtual Private Cloud) 및 서브넷 생성
# VPC는 AWS 클라우드 안에 만드는 나만의 가상 네트워크입니다.
# 마치 회사 건물 안에 내부 네트워크를 구축하는 것과 같습니다.
# 서브넷은 VPC 안에서 네트워크를 더 작은 구역으로 나눈 것입니다.
#
# [네트워크 구조]
# VPC (10.0.0.0/16) - 전체 네트워크
#   ├── 퍼블릭 서브넷 (인터넷 직접 연결) - ALB(로드밸런서) 배치
#   │     ├── public-a (10.0.1.0/24) - 가용영역 A
#   │     └── public-c (10.0.2.0/24) - 가용영역 C
#   ├── 프라이빗 앱 서브넷 (NAT를 통해 인터넷 접근) - EC2 앱 서버 배치
#   │     ├── private-app-a (10.0.11.0/24) - 가용영역 A
#   │     └── private-app-c (10.0.12.0/24) - 가용영역 C
#   └── 프라이빗 DB 서브넷 (인터넷 접근 불가) - RDS 데이터베이스 배치
#         ├── private-db-a (10.0.21.0/24) - 가용영역 A
#         └── private-db-c (10.0.22.0/24) - 가용영역 C
# ============================================

# ============================================
# VPC 생성 - 전체 네트워크의 기반이 되는 가상 사설 클라우드
# CIDR 10.0.0.0/16은 10.0.0.0 ~ 10.0.255.255 범위의 IP를 사용할 수 있다는 뜻입니다 (총 65,536개)
# ============================================
resource "aws_vpc" "main" {          # resource "aws_vpc" "main": AWS VPC 리소스를 "main"이라는 이름으로 생성합니다. 다른 파일에서 aws_vpc.main으로 참조합니다
  cidr_block       = "10.0.0.0/16"  # cidr_block: VPC의 IP 주소 범위입니다. /16은 앞의 16비트(10.0)가 고정이고 나머지를 자유롭게 사용할 수 있다는 뜻입니다
  instance_tenancy = "default"       # instance_tenancy: EC2 인스턴스의 물리적 서버 배치 방식입니다. "default"는 다른 고객과 하드웨어를 공유하는 방식으로, 비용이 가장 저렴합니다

  tags = {                           # tags: 이 VPC에 붙일 태그(이름표)입니다
    Name = "main_vpc"                # Name 태그: AWS 콘솔에서 이 VPC가 "main_vpc"로 표시됩니다
  }
}

# ============================================
# 퍼블릭 서브넷 - 인터넷과 직접 통신 가능한 서브넷
# 인터넷 게이트웨이(IGW)를 통해 외부와 직접 통신할 수 있습니다.
# ALB(Application Load Balancer)가 이 서브넷에 배치됩니다.
# 고가용성을 위해 2개의 가용영역(AZ)에 각각 1개씩 생성합니다.
# ============================================

# 퍼블릭 서브넷 A - 가용영역 us-east-1a에 생성
resource "aws_subnet" "public_a" {   # resource "aws_subnet" "public_a": 퍼블릭 서브넷 A를 생성합니다. aws_subnet.public_a로 참조합니다
  vpc_id            = aws_vpc.main.id  # vpc_id: 이 서브넷이 속할 VPC를 지정합니다. 위에서 만든 main VPC의 ID를 참조합니다
  cidr_block        = "10.0.1.0/24"    # cidr_block: 이 서브넷의 IP 범위입니다. 10.0.1.0 ~ 10.0.1.255 (256개 IP, 실제 사용 가능한 건 251개)
  availability_zone = "us-east-1a"     # availability_zone: 이 서브넷이 위치할 가용영역입니다. 가용영역은 같은 리전 내의 물리적으로 분리된 데이터센터입니다

  tags = {                           # tags: 서브넷에 붙일 태그입니다
    Name = "public-subnet-a"         # Name 태그: AWS 콘솔에서 "public-subnet-a"로 표시됩니다
  }
}

# 퍼블릭 서브넷 C - 가용영역 us-east-1c에 생성 (고가용성을 위한 이중화)
resource "aws_subnet" "public_c" {   # resource "aws_subnet" "public_c": 퍼블릭 서브넷 C를 생성합니다. 서브넷 A와 다른 가용영역에 배치하여 장애 대비를 합니다
  vpc_id            = aws_vpc.main.id  # vpc_id: main VPC에 소속시킵니다
  cidr_block        = "10.0.2.0/24"    # cidr_block: 10.0.2.0 ~ 10.0.2.255 범위 (서브넷 A와 겹치지 않는 별도 IP 대역)
  availability_zone = "us-east-1c"     # availability_zone: 가용영역 C에 배치합니다. A와 다른 물리적 위치이므로 A에 장애가 나도 C는 정상 동작합니다

  tags = {                           # tags: 서브넷에 붙일 태그입니다
    Name = "public-subnet-c"         # Name 태그: AWS 콘솔에서 "public-subnet-c"로 표시됩니다
  }
}

# ============================================
# 프라이빗 앱 서브넷 - EC2 애플리케이션 서버가 배치되는 영역
# 인터넷에서 직접 접근할 수 없고, NAT Gateway를 통해 아웃바운드(나가는) 인터넷만 가능합니다.
# 보안을 위해 앱 서버는 프라이빗 서브넷에 두고, ALB를 통해서만 트래픽을 받습니다.
# ============================================

# 프라이빗 앱 서브넷 A - 가용영역 us-east-1a에 생성
resource "aws_subnet" "private_app_a" {  # resource "aws_subnet" "private_app_a": 프라이빗 앱 서브넷 A를 생성합니다. EC2 앱 서버가 여기에 배치됩니다
  vpc_id            = aws_vpc.main.id    # vpc_id: main VPC에 소속시킵니다
  cidr_block        = "10.0.11.0/24"     # cidr_block: 10.0.11.0 ~ 10.0.11.255 범위. 퍼블릭 서브넷과 겹치지 않도록 11번대를 사용합니다
  availability_zone = "us-east-1a"       # availability_zone: 가용영역 A에 배치합니다

  tags = {                               # tags: 서브넷에 붙일 태그입니다
    Name = "private-app-subnet-a"        # Name 태그: AWS 콘솔에서 "private-app-subnet-a"로 표시됩니다
  }
}

# 프라이빗 앱 서브넷 C - 가용영역 us-east-1c에 생성 (고가용성을 위한 이중화)
resource "aws_subnet" "private_app_c" {  # resource "aws_subnet" "private_app_c": 프라이빗 앱 서브넷 C를 생성합니다. 앱 서버 이중화를 위해 다른 AZ에 배치합니다
  vpc_id            = aws_vpc.main.id    # vpc_id: main VPC에 소속시킵니다
  cidr_block        = "10.0.12.0/24"     # cidr_block: 10.0.12.0 ~ 10.0.12.255 범위
  availability_zone = "us-east-1c"       # availability_zone: 가용영역 C에 배치합니다

  tags = {                               # tags: 서브넷에 붙일 태그입니다
    Name = "private-app-subnet-c"        # Name 태그: AWS 콘솔에서 "private-app-subnet-c"로 표시됩니다
  }
}

# ============================================
# 프라이빗 DB 서브넷 - RDS 데이터베이스가 배치되는 영역
# 인터넷 접근이 완전히 차단되어 가장 보안이 높은 영역입니다.
# 오직 앱 서브넷의 EC2 서버에서만 접근할 수 있습니다.
# RDS는 최소 2개의 가용영역에 서브넷이 필요합니다 (AWS 요구사항).
# ============================================

# 프라이빗 DB 서브넷 A - 가용영역 us-east-1a에 생성
resource "aws_subnet" "private_db_a" {   # resource "aws_subnet" "private_db_a": 프라이빗 DB 서브넷 A를 생성합니다. RDS 데이터베이스가 여기에 배치됩니다
  vpc_id            = aws_vpc.main.id    # vpc_id: main VPC에 소속시킵니다
  cidr_block        = "10.0.21.0/24"     # cidr_block: 10.0.21.0 ~ 10.0.21.255 범위. DB용으로 21번대를 사용하여 앱 서브넷과 구분합니다
  availability_zone = "us-east-1a"       # availability_zone: 가용영역 A에 배치합니다

  tags = {                               # tags: 서브넷에 붙일 태그입니다
    Name = "private-db-subnet-a"         # Name 태그: AWS 콘솔에서 "private-db-subnet-a"로 표시됩니다
  }
}

# 프라이빗 DB 서브넷 C - 가용영역 us-east-1c에 생성 (RDS 다중 AZ 요구사항 충족)
resource "aws_subnet" "private_db_c" {   # resource "aws_subnet" "private_db_c": 프라이빗 DB 서브넷 C를 생성합니다. RDS 서브넷 그룹에 최소 2개 AZ가 필요하므로 반드시 생성해야 합니다
  vpc_id            = aws_vpc.main.id    # vpc_id: main VPC에 소속시킵니다
  cidr_block        = "10.0.22.0/24"     # cidr_block: 10.0.22.0 ~ 10.0.22.255 범위
  availability_zone = "us-east-1c"       # availability_zone: 가용영역 C에 배치합니다

  tags = {                               # tags: 서브넷에 붙일 태그입니다
    Name = "private-db-subnet-c"         # Name 태그: AWS 콘솔에서 "private-db-subnet-c"로 표시됩니다
  }
}
