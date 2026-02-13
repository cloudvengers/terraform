# Internet Gateway 생성
resource "aws_internet_gateway" "igw" {                            # Internet Gateway 리소스 정의
  vpc_id = aws_vpc.main.id                                         # 연결할 VPC ID

  tags = {                                                         # 태그 맵
    Name = "igw"                                                   # Internet Gateway 이름
  }
}
