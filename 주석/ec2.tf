# ============================================
# EC2 인스턴스 (앱 서버) 생성
#
# EC2(Elastic Compute Cloud)는 AWS의 가상 서버입니다.
# 여기서는 웹 애플리케이션을 실행할 앱 서버 2대를 생성합니다.
# 고가용성을 위해 서로 다른 가용영역(AZ-a, AZ-c)에 각각 1대씩 배치합니다.
# 하나의 서버에 장애가 발생해도 다른 서버가 서비스를 계속할 수 있습니다.
#
# [트래픽 흐름]
# 사용자 → ALB → 앱 서버 A 또는 앱 서버 C (로드밸런싱)
# ============================================

# 앱 서버 A - 가용영역 A의 프라이빗 서브넷에 배치
resource "aws_instance" "app_a" {     # resource "aws_instance" "app_a": EC2 인스턴스를 "app_a"라는 이름으로 생성합니다. 가용영역 A에 배치되는 앱 서버입니다
  ami                    = var.ami_id              # ami: 사용할 AMI(운영체제 이미지) ID입니다. variables.tf에서 선언하고 terraform.tfvars에서 값을 지정한 변수를 참조합니다
  instance_type          = var.instance_type        # instance_type: 인스턴스 사양입니다. 기본값 "t2.micro"는 vCPU 1개, 메모리 1GB로 프리티어 사용 가능합니다
  subnet_id              = aws_subnet.private_app_a.id       # subnet_id: 이 인스턴스를 배치할 서브넷입니다. 프라이빗 앱 서브넷 A에 배치하여 인터넷에서 직접 접근할 수 없게 합니다
  vpc_security_group_ids = [aws_security_group.app.id]       # vpc_security_group_ids: 적용할 보안 그룹 목록입니다. 앱 보안 그룹을 적용하여 ALB에서 오는 80번 포트 트래픽만 허용합니다

  tags = {                             # tags: EC2 인스턴스에 붙일 태그입니다
    Name = "app-server-a"             # Name 태그: AWS 콘솔에서 "app-server-a"로 표시됩니다. 어떤 서버인지 쉽게 구분할 수 있습니다
  }
}

# 앱 서버 C - 가용영역 C의 프라이빗 서브넷에 배치 (고가용성을 위한 이중화)
resource "aws_instance" "app_c" {     # resource "aws_instance" "app_c": 두 번째 EC2 인스턴스입니다. 가용영역 C에 배치하여 AZ-a 장애 시에도 서비스가 유지됩니다
  ami                    = var.ami_id              # ami: 앱 서버 A와 동일한 AMI를 사용합니다. 두 서버가 같은 운영체제와 환경을 갖도록 합니다
  instance_type          = var.instance_type        # instance_type: 앱 서버 A와 동일한 사양을 사용합니다
  subnet_id              = aws_subnet.private_app_c.id       # subnet_id: 프라이빗 앱 서브넷 C에 배치합니다. 서버 A와 다른 가용영역에 있어 물리적으로 분리됩니다
  vpc_security_group_ids = [aws_security_group.app.id]       # vpc_security_group_ids: 앱 서버 A와 동일한 보안 그룹을 적용합니다

  tags = {                             # tags: EC2 인스턴스에 붙일 태그입니다
    Name = "app-server-c"             # Name 태그: AWS 콘솔에서 "app-server-c"로 표시됩니다
  }
}
