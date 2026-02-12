# 1. 퍼블릭 서브넷 A의 NAT Gateway에서 사용할 eip
resource "aws_eip" "nat_eip_a" {
  tags = {
    Name = "nat-eip-a"
  }
}

# 2. 퍼블릭 서브넷 C의 NAT Gateway에서 사용할 eip
resource "aws_eip" "nat_eip_c" {
  tags = {
    Name = "nat-eip-c"
  }
}

# 3. 퍼블릭 서브넷 A의 Nat Gateway
resource "aws_nat_gateway" "nat_gw_a" {
  allocation_id = aws_eip.nat_eip_a.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "public-subnet-a-nat-gw"
  }
}

# 4. 퍼블릭 서브넷 C의 Nat Gateway
resource "aws_nat_gateway" "nat_gw_c" {
  allocation_id = aws_eip.nat_eip_c.id
  subnet_id     = aws_subnet.public_c.id

  tags = {
    Name = "public-subnet-c-nat-gw"
  }
}