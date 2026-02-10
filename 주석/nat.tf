# ============================================
# NAT Gateway 및 프라이빗 앱 서브넷 라우팅 설정
#
# NAT(Network Address Translation) Gateway는 프라이빗 서브넷의 리소스가
# 인터넷으로 나가는(아웃바운드) 통신만 가능하게 해주는 장치입니다.
# 예: 프라이빗 서브넷의 EC2가 소프트웨어 업데이트를 다운로드할 때 사용
# 외부에서 프라이빗 서브넷으로 직접 접근하는 것은 불가능합니다 (보안 유지).
#
# [트래픽 흐름]
# 프라이빗 EC2 → NAT Gateway(퍼블릭 서브넷) → IGW → 인터넷
# ============================================

# NAT Gateway에 할당할 탄력적 IP(Elastic IP) 생성
# 탄력적 IP는 AWS에서 제공하는 고정 공인 IP 주소입니다.
# NAT Gateway는 반드시 공인 IP가 있어야 인터넷과 통신할 수 있습니다.
resource "aws_eip" "nat" {           # resource "aws_eip" "nat": 탄력적 IP를 "nat"이라는 이름으로 생성합니다. 이 IP는 NAT Gateway에 연결됩니다
  tags = {                           # tags: 탄력적 IP에 붙일 태그입니다
    Name = "nat-eip"                 # Name 태그: AWS 콘솔에서 "nat-eip"로 표시됩니다
  }
}

# NAT Gateway 생성 - 프라이빗 서브넷의 인터넷 아웃바운드 통신을 담당합니다
# 반드시 퍼블릭 서브넷에 배치해야 합니다 (IGW를 통해 인터넷에 접근해야 하므로)
resource "aws_nat_gateway" "main" {  # resource "aws_nat_gateway" "main": NAT Gateway를 "main"이라는 이름으로 생성합니다
  allocation_id = aws_eip.nat.id     # allocation_id: 위에서 만든 탄력적 IP를 NAT Gateway에 연결합니다. 이 IP가 NAT Gateway의 공인 IP가 됩니다
  subnet_id     = aws_subnet.public_a.id  # subnet_id: NAT Gateway를 배치할 서브넷입니다. 퍼블릭 서브넷 A에 배치하여 IGW를 통해 인터넷에 접근합니다

  tags = {                           # tags: NAT Gateway에 붙일 태그입니다
    Name = "main-nat-gw"            # Name 태그: AWS 콘솔에서 "main-nat-gw"로 표시됩니다
  }
}

# ============================================
# 프라이빗 앱 서브넷용 라우팅 테이블
# 라우팅 테이블은 네트워크 트래픽이 어디로 가야 하는지 알려주는 길 안내 표지판입니다.
# 프라이빗 앱 서브넷의 트래픽을 NAT Gateway로 보내도록 설정합니다.
# ============================================
resource "aws_route_table" "private_app" {  # resource "aws_route_table" "private_app": 프라이빗 앱 서브넷 전용 라우팅 테이블을 생성합니다
  vpc_id = aws_vpc.main.id                  # vpc_id: 이 라우팅 테이블이 속할 VPC입니다. main VPC에 생성합니다

  tags = {                                   # tags: 라우팅 테이블에 붙일 태그입니다
    Name = "private-app-rt"                  # Name 태그: AWS 콘솔에서 "private-app-rt"로 표시됩니다
  }
}

# 프라이빗 앱 서브넷의 인터넷 트래픽을 NAT Gateway로 보내는 라우팅 규칙
resource "aws_route" "private_app_internet" {  # resource "aws_route" "private_app_internet": 라우팅 규칙을 생성합니다. "VPC 외부로 가는 트래픽은 NAT Gateway로 보내라"는 규칙입니다
  route_table_id         = aws_route_table.private_app.id  # route_table_id: 이 규칙을 추가할 라우팅 테이블입니다. 위에서 만든 프라이빗 앱 라우팅 테이블에 추가합니다
  destination_cidr_block = "0.0.0.0/0"                     # destination_cidr_block: 목적지 IP 범위입니다. "0.0.0.0/0"은 모든 IP 주소를 의미합니다 (= 인터넷의 모든 곳)
  nat_gateway_id         = aws_nat_gateway.main.id         # nat_gateway_id: 트래픽을 전달할 대상입니다. 위에서 만든 NAT Gateway로 보냅니다
}

# 프라이빗 앱 서브넷 A에 라우팅 테이블 연결
# 라우팅 테이블을 만들었으면 실제 서브넷에 연결해야 적용됩니다
resource "aws_route_table_association" "private_app_a" {  # resource "aws_route_table_association": 서브넷과 라우팅 테이블을 연결하는 리소스입니다
  subnet_id      = aws_subnet.private_app_a.id           # subnet_id: 연결할 서브넷입니다. 프라이빗 앱 서브넷 A를 지정합니다
  route_table_id = aws_route_table.private_app.id        # route_table_id: 연결할 라우팅 테이블입니다. 위에서 만든 프라이빗 앱 라우팅 테이블을 지정합니다
}

# 프라이빗 앱 서브넷 C에도 같은 라우팅 테이블 연결
# 서브넷 A와 C 모두 같은 라우팅 테이블을 사용하여 동일한 네트워크 규칙을 적용합니다
resource "aws_route_table_association" "private_app_c" {  # resource "aws_route_table_association": 서브넷 C에도 라우팅 테이블을 연결합니다
  subnet_id      = aws_subnet.private_app_c.id           # subnet_id: 프라이빗 앱 서브넷 C를 지정합니다
  route_table_id = aws_route_table.private_app.id        # route_table_id: 같은 프라이빗 앱 라우팅 테이블을 연결합니다
}
