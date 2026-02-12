# ALB 보안 그룹
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  # 인바운드 규칙 1 : HTTP(80번 포트) 허용
  ingress {                     # 인바운드
    from_port   = 80            # 허용할 포트 범위의 시작
    to_port     = 80            # 허용할 포트 범위의 끝
    protocol    = "tcp"         # 허용할 프로토콜
    cidr_blocks = ["0.0.0.0/0"] # 접근을 허용할 IP 범위
  }

  # 인바운드 규칙 2 : HTTPS(443번 포트) 허용
  ingress {                     # 인바운드
    from_port   = 443           # 허용할 포트 범위의 시작
    to_port     = 443           # 허용할 포트 범위의 끝
    protocol    = "tcp"         # 허용할 프로토콜
    cidr_blocks = ["0.0.0.0/0"] # 접근을 허용할 IP 범위
  }

  # 아웃바운드 규칙 : 모든 트래픽 허용
  # ALB가 백엔드 앱 서버로 트래픽을 전달해야 하므로 나가는 트래픽은 모두 허용
  egress {                      # 아웃바운드
    from_port   = 0             # 0은 모든 포트의 시작
    to_port     = 0             # 0은 모든 포트의 끝
    protocol    = "-1"          # -1은 모든 프로토콜을 의미
    cidr_blocks = ["0.0.0.0/0"] # 모든 IP로 나가는 트래픽을 허용
  }

  tags = {
    Name = "alb-sg"
  }
}

# =======================================
# APP 서버(EC2) 보안 그룹
# ALB 보안 그룹에서 오는 HTTP(80) 트래픽만 허용
# ALB를 거쳐서 인터넷에서 직접 접근 불가능하게
# => 앱 서버가 외부 공격에 직접 노출 안됨

resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "Security group for App Servers(EC2)"
  vpc_id      = aws_vpc.main.id

  ingress { # 인바운드: ALB에서 전달되는 트래픽만 허용
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # ALB 보안 그룹에 속한 리소스(ALB)에서 오는 트래픽만 허용
  }

  # 아웃바운드 : 모든 트래픽 허용
  # 앱 서버가 외부 API 호출, 패키지 다운로드가 가능하게 나가는 트래픽은 모두 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-sg"
  }
}

# =======================================
# DB 보안 그룹
# 앱 서버 보안그룹에서 오는 MySQL(3306) 트래픽만 허용

resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main.id

  # 인바운드 규칙: 앱 서버 보안그룹에서 오는 MySQL(3306) 트래픽만 허용
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id] # 앱 보안 그룹에서 오는 트래픽만 허용
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}