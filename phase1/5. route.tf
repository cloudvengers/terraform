# 1. 퍼블릭 서브넷 전용 라우팅 테이블 생성
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "public-rt"
  }
}

# 2. 모든 외부 트래픽(0.0.0.0/0)을 인터넷 게이트웨이(igw)로 보내는 라우팅 규칙
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# 3. 라우팅 테이블을 만들고 규칙 추가했다면, 실제 서브넷에 연결

# 퍼블릭 서브넷 A에 라우팅 테이블 연결
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# 퍼블릭 서브넷 C에 라우팅 테이블 연결
resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

# ===========================================================

# 1. 프라이빗 앱 서브넷 A 전용 라우팅 테이블
resource "aws_route_table" "private_app_a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-app-rt-a"
  }
}

resource "aws_route" "private_app_internet_a" {
  route_table_id         = aws_route_table.private_app_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw_a.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_app_a.id
  route_table_id = aws_route_table.private_app_a.id
}

# 2. 프라이빗 앱 서브넷 C 전용 라우팅 테이블
resource "aws_route_table" "private_app_c" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-app-rt-c"
  }
}

resource "aws_route" "private_app_internet_c" {
  route_table_id         = aws_route_table.private_app_c.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw_c.id
}

resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_app_c.id
  route_table_id = aws_route_table.private_app_c.id
}

# 3. 프라이빗 db 서브넷 A 전용 라우팅 테이블
resource "aws_route_table" "private_db_a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-db-rt-a"
  }
}

resource "aws_route_table_association" "private_db_a" {
  subnet_id      = aws_subnet.private_db_a.id
  route_table_id = aws_route_table.private_db_a.id
}

# 4. 프라이빗 db 서브넷 C 전용 라우팅 테이블
resource "aws_route_table" "private_db_c" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-db-rt-c"
  }
}

resource "aws_route_table_association" "private_db_c" {
  subnet_id      = aws_subnet.private_db_c.id
  route_table_id = aws_route_table.private_db_c.id
}