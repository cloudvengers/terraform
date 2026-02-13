# =====================================================
# ALB Security Group
# =====================================================

# ALB 보안 그룹 생성
resource "aws_security_group" "alb" {                              # ALB Security Group 리소스 정의
  name = "alb-sg"                                                  # 보안 그룹 이름
  description = "Security group for ALB"                           # 보안 그룹 설명
  vpc_id = aws_vpc.main.id                                         # VPC ID

  tags = {                                                         # 태그 맵
    Name = "alb-sg"                                                # 보안 그룹 이름 태그
  }
}

# ALB 인바운드 규칙 - HTTP(80) 허용
resource "aws_vpc_security_group_ingress_rule" "alb_http" {        # Ingress Rule 리소스 정의
  security_group_id = aws_security_group.alb.id                    # 보안 그룹 ID
  cidr_ipv4 = "0.0.0.0/0"                                          # 소스 CIDR (모든 IP)
  from_port = 80                                                   # 시작 포트
  to_port = 80                                                     # 종료 포트
  ip_protocol = "tcp"                                              # 프로토콜
}

# ALB 인바운드 규칙 - HTTPS(443) 허용
resource "aws_vpc_security_group_ingress_rule" "alb_https" {       # Ingress Rule 리소스 정의
  security_group_id = aws_security_group.alb.id                    # 보안 그룹 ID
  cidr_ipv4 = "0.0.0.0/0"                                          # 소스 CIDR (모든 IP)
  from_port = 443                                                  # 시작 포트
  to_port = 443                                                    # 종료 포트
  ip_protocol = "tcp"                                              # 프로토콜
}

# ALB 아웃바운드 규칙 - 모든 트래픽 허용
resource "aws_vpc_security_group_egress_rule" "alb_all" {          # Egress Rule 리소스 정의
  security_group_id = aws_security_group.alb.id                    # 보안 그룹 ID
  cidr_ipv4 = "0.0.0.0/0"                                          # 목적지 CIDR (모든 IP)
  ip_protocol = "-1"                                               # 모든 프로토콜
}

# =====================================================
# App Server Security Group
# =====================================================

# App 서버 보안 그룹 생성
resource "aws_security_group" "app" {                              # App Security Group 리소스 정의
  name = "app-sg"                                                  # 보안 그룹 이름
  description = "Security group for App Server(EC2)"              # 보안 그룹 설명
  vpc_id = aws_vpc.main.id                                         # VPC ID
  
  tags = {                                                         # 태그 맵
    Name = "app-sg"                                                # 보안 그룹 이름 태그
  }
}

# App 인바운드 규칙 - ALB에서 오는 HTTP(80) 허용
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {    # Ingress Rule 리소스 정의
  security_group_id = aws_security_group.app.id                    # 보안 그룹 ID
  referenced_security_group_id = aws_security_group.alb.id         # 소스 보안 그룹 ID (ALB)
  from_port = 80                                                   # 시작 포트
  to_port = 80                                                     # 종료 포트
  ip_protocol = "tcp"                                              # 프로토콜
}

# App 아웃바운드 규칙 - 모든 트래픽 허용
resource "aws_vpc_security_group_egress_rule" "app_all" {          # Egress Rule 리소스 정의
  security_group_id = aws_security_group.app.id                    # 보안 그룹 ID
  cidr_ipv4 = "0.0.0.0/0"                                          # 목적지 CIDR (모든 IP)
  ip_protocol = "-1"                                               # 모든 프로토콜
}

# =====================================================
# DB Security Group
# =====================================================

# DB 보안 그룹 생성
resource "aws_security_group" "db" {                               # DB Security Group 리소스 정의
  name = "db-sg"                                                   # 보안 그룹 이름
  description = "Security group for DB(RDS)"                       # 보안 그룹 설명
  vpc_id = aws_vpc.main.id                                         # VPC ID
  
  tags = {                                                         # 태그 맵
    Name = "db-sg"                                                 # 보안 그룹 이름 태그
  }
}

# DB 인바운드 규칙 - App 서버에서 오는 MySQL(3306) 허용
resource "aws_vpc_security_group_ingress_rule" "db_from_alb" {     # Ingress Rule 리소스 정의
  security_group_id = aws_security_group.db.id                     # 보안 그룹 ID
  referenced_security_group_id = aws_security_group.app.id         # 소스 보안 그룹 ID (App)
  from_port = 3306                                                 # 시작 포트
  to_port = 3306                                                   # 종료 포트
  ip_protocol = "tcp"                                              # 프로토콜
}

# DB 아웃바운드 규칙 - 모든 트래픽 허용
resource "aws_vpc_security_group_egress_rule" "db_all" {           # Egress Rule 리소스 정의
  security_group_id = aws_security_group.db.id                     # 보안 그룹 ID
  cidr_ipv4 = "0.0.0.0/0"                                          # 목적지 CIDR (모든 IP)
  ip_protocol = "-1"                                               # 모든 프로토콜
}
