# ============================================
# 퍼블릭 서브넷용 라우팅 테이블 및 라우팅 규칙
#
# 퍼블릭 서브넷이 인터넷과 통신하려면 라우팅 테이블에
# "인터넷으로 가는 트래픽은 IGW(인터넷 게이트웨이)로 보내라"는 규칙이 필요합니다.
#
# [트래픽 흐름]
# 퍼블릭 서브넷 리소스(ALB 등) ↔ IGW ↔ 인터넷
# ============================================

# 퍼블릭 서브넷 전용 라우팅 테이블 생성
resource "aws_route_table" "public" {  # resource "aws_route_table" "public": 퍼블릭 서브넷에서 사용할 라우팅 테이블을 생성합니다. 라우팅 테이블은 트래픽의 경로를 결정하는 규칙 모음입니다
  vpc_id = aws_vpc.main.id            # vpc_id: 이 라우팅 테이블이 속할 VPC입니다. main VPC에 생성합니다

  tags = {                             # tags: 라우팅 테이블에 붙일 태그입니다
    Name = "public-rt"                 # Name 태그: AWS 콘솔에서 "public-rt"로 표시됩니다
  }
}

# 모든 외부 트래픽(0.0.0.0/0)을 인터넷 게이트웨이(IGW)로 보내는 라우팅 규칙
# 이 규칙이 있어야 퍼블릭 서브넷의 리소스가 인터넷에 접근할 수 있습니다
resource "aws_route" "public_internet" {  # resource "aws_route" "public_internet": 라우팅 규칙을 생성합니다. "인터넷으로 가는 모든 트래픽은 IGW로 보내라"는 규칙입니다
  route_table_id         = aws_route_table.public.id       # route_table_id: 이 규칙을 추가할 라우팅 테이블입니다. 위에서 만든 퍼블릭 라우팅 테이블에 추가합니다
  destination_cidr_block = "0.0.0.0/0"                     # destination_cidr_block: 목적지 IP 범위입니다. "0.0.0.0/0"은 VPC 외부의 모든 IP 주소(= 인터넷 전체)를 의미합니다
  gateway_id             = aws_internet_gateway.igw.id     # gateway_id: 트래픽을 전달할 대상입니다. igw.tf에서 만든 인터넷 게이트웨이로 보냅니다
}

# 퍼블릭 서브넷 A에 라우팅 테이블 연결
# 라우팅 테이블을 만들고 규칙을 추가했으면, 실제 서브넷에 연결해야 적용됩니다
resource "aws_route_table_association" "public_a" {  # resource "aws_route_table_association": 서브넷과 라우팅 테이블을 연결하는 리소스입니다. 이 연결이 없으면 서브넷은 VPC 기본 라우팅 테이블을 사용합니다
  subnet_id      = aws_subnet.public_a.id           # subnet_id: 연결할 서브넷입니다. vpc.tf에서 만든 퍼블릭 서브넷 A를 지정합니다
  route_table_id = aws_route_table.public.id        # route_table_id: 연결할 라우팅 테이블입니다. 위에서 만든 퍼블릭 라우팅 테이블을 지정합니다
}

# 퍼블릭 서브넷 C에도 같은 라우팅 테이블 연결
resource "aws_route_table_association" "public_c" {  # resource "aws_route_table_association": 퍼블릭 서브넷 C에도 동일한 라우팅 테이블을 연결합니다. 두 서브넷 모두 IGW를 통해 인터넷에 접근할 수 있게 됩니다
  subnet_id      = aws_subnet.public_c.id           # subnet_id: 퍼블릭 서브넷 C를 지정합니다
  route_table_id = aws_route_table.public.id        # route_table_id: 같은 퍼블릭 라우팅 테이블을 연결합니다
}
