# Elastic IP for NAT Gateway A
resource "aws_eip" "nat_eip_a" {                                   # Elastic IP 리소스 정의 (NAT Gateway A용)
  
  tags = {                                                         # 태그 맵
    Name = "nat-eip-a"                                             # EIP 이름
  }
}

# Elastic IP for NAT Gateway C
resource "aws_eip" "nat_eip_c" {                                   # Elastic IP 리소스 정의 (NAT Gateway C용)
  
  tags = {                                                         # 태그 맵
    Name = "nat-eip-c"                                             # EIP 이름
  }
}

# NAT Gateway A (Public Subnet A)
resource "aws_nat_gateway" "nat_gw_a" {                            # NAT Gateway 리소스 정의 (가용 영역 A)
  allocation_id = aws_eip.nat_eip_a.id                             # 연결할 Elastic IP ID
  subnet_id     = aws_subnet.public_a.id                           # NAT Gateway를 배치할 Public Subnet ID

  tags = {                                                         # 태그 맵
    Name = "public-subnet-a-nat-gw"                                # NAT Gateway 이름
  }
}

# NAT Gateway C (Public Subnet C)
resource "aws_nat_gateway" "nat_gw_c" {                            # NAT Gateway 리소스 정의 (가용 영역 C)
  allocation_id = aws_eip.nat_eip_c.id                             # 연결할 Elastic IP ID
  subnet_id     = aws_subnet.public_c.id                           # NAT Gateway를 배치할 Public Subnet ID

  tags = {                                                         # 태그 맵
    Name = "public-subnet-c-nat-gw"                                # NAT Gateway 이름
  }
}
