# =====================================================
# Public Subnet Route Table
# =====================================================

# Public Route Table 생성
resource "aws_route_table" "public" {                              # Public Route Table 리소스 정의
  vpc_id = aws_vpc.main.id                                         # VPC ID

  tags = {                                                         # 태그 맵
    Name = "public-rt"                                             # Route Table 이름
  }
}

# Public Route - Internet Gateway로 라우팅
resource "aws_route" "public_internet" {                           # Public Route 리소스 정의
  route_table_id         = aws_route_table.public.id               # Route Table ID
  destination_cidr_block = "0.0.0.0/0"                             # 목적지 CIDR (모든 외부 트래픽)
  gateway_id             = aws_internet_gateway.igw.id             # Internet Gateway ID
}

# Public Subnet A에 Route Table 연결
resource "aws_route_table_association" "public_a" {                # Route Table Association 리소스 정의
  subnet_id      = aws_subnet.public_a.id                          # 연결할 Subnet ID
  route_table_id = aws_route_table.public.id                       # 연결할 Route Table ID
}

# Public Subnet C에 Route Table 연결
resource "aws_route_table_association" "public_c" {                # Route Table Association 리소스 정의
  subnet_id      = aws_subnet.public_c.id                          # 연결할 Subnet ID
  route_table_id = aws_route_table.public.id                       # 연결할 Route Table ID
}

# =====================================================
# Private App Subnet A Route Table
# =====================================================

# Private App Route Table A 생성
resource "aws_route_table" "private_app_a" {                       # Private App Route Table 리소스 정의 (가용 영역 A)
  vpc_id = aws_vpc.main.id                                         # VPC ID

  tags = {                                                         # 태그 맵
    Name = "private-app-rt-a"                                      # Route Table 이름
  }
}

# Private App Route A - NAT Gateway A로 라우팅
resource "aws_route" "private_app_internet_a" {                    # Private App Route 리소스 정의
  route_table_id         = aws_route_table.private_app_a.id        # Route Table ID
  destination_cidr_block = "0.0.0.0/0"                             # 목적지 CIDR (모든 외부 트래픽)
  nat_gateway_id         = aws_nat_gateway.nat_gw_a.id             # NAT Gateway A ID
}

# Private App Subnet A에 Route Table 연결
resource "aws_route_table_association" "private_a" {               # Route Table Association 리소스 정의
  subnet_id      = aws_subnet.private_app_a.id                     # 연결할 Subnet ID
  route_table_id = aws_route_table.private_app_a.id                # 연결할 Route Table ID
}

# =====================================================
# Private App Subnet C Route Table
# =====================================================

# Private App Route Table C 생성
resource "aws_route_table" "private_app_c" {                       # Private App Route Table 리소스 정의 (가용 영역 C)
  vpc_id = aws_vpc.main.id                                         # VPC ID

  tags = {                                                         # 태그 맵
    Name = "private-app-rt-c"                                      # Route Table 이름
  }
}

# Private App Route C - NAT Gateway C로 라우팅
resource "aws_route" "private_app_internet_c" {                    # Private App Route 리소스 정의
  route_table_id         = aws_route_table.private_app_c.id        # Route Table ID
  destination_cidr_block = "0.0.0.0/0"                             # 목적지 CIDR (모든 외부 트래픽)
  nat_gateway_id         = aws_nat_gateway.nat_gw_c.id             # NAT Gateway C ID
}

# Private App Subnet C에 Route Table 연결
resource "aws_route_table_association" "private_c" {               # Route Table Association 리소스 정의
  subnet_id      = aws_subnet.private_app_c.id                     # 연결할 Subnet ID
  route_table_id = aws_route_table.private_app_c.id                # 연결할 Route Table ID
}

# =====================================================
# Private DB Subnet A Route Table
# =====================================================

# Private DB Route Table A 생성
resource "aws_route_table" "private_db_a" {                        # Private DB Route Table 리소스 정의 (가용 영역 A)
  vpc_id = aws_vpc.main.id                                         # VPC ID

  tags = {                                                         # 태그 맵
    Name = "private-db-rt-a"                                       # Route Table 이름
  }
}

# Private DB Subnet A에 Route Table 연결
resource "aws_route_table_association" "private_db_a" {            # Route Table Association 리소스 정의
  subnet_id      = aws_subnet.private_db_a.id                      # 연결할 Subnet ID
  route_table_id = aws_route_table.private_db_a.id                 # 연결할 Route Table ID
}

# =====================================================
# Private DB Subnet C Route Table
# =====================================================

# Private DB Route Table C 생성
resource "aws_route_table" "private_db_c" {                        # Private DB Route Table 리소스 정의 (가용 영역 C)
  vpc_id = aws_vpc.main.id                                         # VPC ID

  tags = {                                                         # 태그 맵
    Name = "private-db-rt-c"                                       # Route Table 이름
  }
}

# Private DB Subnet C에 Route Table 연결
resource "aws_route_table_association" "private_db_c" {            # Route Table Association 리소스 정의
  subnet_id      = aws_subnet.private_db_c.id                      # 연결할 Subnet ID
  route_table_id = aws_route_table.private_db_c.id                 # 연결할 Route Table ID
}
