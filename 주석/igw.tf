# ============================================
# 인터넷 게이트웨이 (Internet Gateway, IGW)
# VPC가 인터넷과 통신할 수 있도록 연결해주는 관문(출입구)입니다.
# 집에 비유하면 현관문과 같은 역할입니다.
# 퍼블릭 서브넷의 리소스(ALB 등)가 인터넷에 접근하려면 반드시 IGW가 필요합니다.
# VPC 하나당 IGW는 하나만 연결할 수 있습니다.
# ============================================
resource "aws_internet_gateway" "igw" {  # resource "aws_internet_gateway" "igw": 인터넷 게이트웨이를 "igw"라는 이름으로 생성합니다. aws_internet_gateway.igw로 참조합니다
  vpc_id = aws_vpc.main.id              # vpc_id: 이 인터넷 게이트웨이를 연결할 VPC입니다. vpc.tf에서 만든 main VPC에 연결합니다. 이렇게 해야 VPC 안의 리소스가 인터넷을 사용할 수 있습니다

  tags = {                               # tags: 인터넷 게이트웨이에 붙일 태그입니다
    Name = "main-igw"                    # Name 태그: AWS 콘솔에서 "main-igw"로 표시됩니다
  }
}
