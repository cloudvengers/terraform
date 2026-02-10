# ============================================
# 보안 그룹 (Security Group) 설정
#
# 보안 그룹은 AWS 리소스의 방화벽 역할을 합니다.
# 어떤 트래픽을 허용하고 차단할지 규칙을 정의합니다.
# - ingress (인바운드): 외부에서 리소스로 들어오는 트래픽 규칙
# - egress (아웃바운드): 리소스에서 외부로 나가는 트래픽 규칙
#
# [보안 그룹 체인]
# 인터넷 → ALB SG(80,443 허용) → App SG(ALB에서만 80 허용) → DB SG(App에서만 3306 허용)
# 이렇게 단계별로 접근을 제한하여 보안을 강화합니다.
# ============================================

# ============================================
# ALB(Application Load Balancer) 보안 그룹
# 외부 인터넷에서 HTTP(80)와 HTTPS(443) 트래픽을 허용합니다.
# ALB는 사용자의 웹 요청을 가장 먼저 받는 곳이므로 인터넷에 공개됩니다.
# ============================================
resource "aws_security_group" "alb" {  # resource "aws_security_group" "alb": ALB용 보안 그룹을 생성합니다. aws_security_group.alb로 참조합니다
  name        = "alb-sg"               # name: 보안 그룹의 이름입니다. AWS 내부에서 이 이름으로 식별됩니다
  description = "Security group for ALB"  # description: 이 보안 그룹의 용도를 설명하는 텍스트입니다
  vpc_id      = aws_vpc.main.id        # vpc_id: 이 보안 그룹이 속할 VPC입니다. 보안 그룹은 반드시 하나의 VPC에 소속되어야 합니다

  # 인바운드 규칙 1: HTTP(80번 포트) 허용
  # 웹 브라우저에서 http://로 접속할 때 사용하는 포트입니다
  ingress {                            # ingress: 인바운드(들어오는) 트래픽 규칙을 정의합니다
    from_port   = 80                   # from_port: 허용할 포트 범위의 시작입니다. 80은 HTTP 표준 포트입니다
    to_port     = 80                   # to_port: 허용할 포트 범위의 끝입니다. from_port와 같으면 단일 포트만 허용합니다
    protocol    = "tcp"                # protocol: 허용할 프로토콜입니다. "tcp"는 웹 통신에 사용되는 기본 프로토콜입니다
    cidr_blocks = ["0.0.0.0/0"]        # cidr_blocks: 접근을 허용할 IP 범위입니다. "0.0.0.0/0"은 모든 IP(= 인터넷의 누구나)를 의미합니다
  }

  # 인바운드 규칙 2: HTTPS(443번 포트) 허용
  # 웹 브라우저에서 https://로 접속할 때 사용하는 암호화된 포트입니다
  ingress {                            # ingress: 두 번째 인바운드 규칙입니다. 보안 그룹에는 여러 개의 규칙을 추가할 수 있습니다
    from_port   = 443                  # from_port: 443은 HTTPS(보안 HTTP) 표준 포트입니다
    to_port     = 443                  # to_port: 443 포트만 허용합니다
    protocol    = "tcp"                # protocol: TCP 프로토콜을 사용합니다
    cidr_blocks = ["0.0.0.0/0"]        # cidr_blocks: 모든 IP에서 접근을 허용합니다. HTTPS도 공개 웹 서비스이므로 모든 사용자가 접근 가능해야 합니다
  }

  # 아웃바운드 규칙: 모든 트래픽 허용
  # ALB가 백엔드 앱 서버로 트래픽을 전달해야 하므로 나가는 트래픽은 모두 허용합니다
  egress {                             # egress: 아웃바운드(나가는) 트래픽 규칙을 정의합니다
    from_port   = 0                    # from_port: 0은 모든 포트의 시작을 의미합니다
    to_port     = 0                    # to_port: 0은 모든 포트의 끝을 의미합니다 (protocol이 "-1"일 때 0은 "모든 포트"를 뜻합니다)
    protocol    = "-1"                 # protocol: "-1"은 모든 프로토콜(TCP, UDP, ICMP 등)을 의미합니다
    cidr_blocks = ["0.0.0.0/0"]        # cidr_blocks: 모든 IP로 나가는 트래픽을 허용합니다
  }

  tags = {                             # tags: 보안 그룹에 붙일 태그입니다
    Name = "alb-sg"                    # Name 태그: AWS 콘솔에서 "alb-sg"로 표시됩니다
  }
}

# ============================================
# 앱 서버(EC2) 보안 그룹
# ALB 보안 그룹에서 오는 HTTP(80) 트래픽만 허용합니다.
# 인터넷에서 직접 접근할 수 없고, 반드시 ALB를 거쳐야 합니다.
# 이렇게 하면 앱 서버가 외부 공격에 직접 노출되지 않습니다.
# ============================================
resource "aws_security_group" "app" {  # resource "aws_security_group" "app": 앱 서버용 보안 그룹을 생성합니다. EC2 인스턴스에 적용됩니다
  name        = "app-sg"               # name: 보안 그룹 이름입니다
  description = "Security group for App servers"  # description: 앱 서버용 보안 그룹임을 설명합니다
  vpc_id      = aws_vpc.main.id        # vpc_id: main VPC에 소속시킵니다

  # 인바운드 규칙: ALB 보안 그룹에서 오는 HTTP(80) 트래픽만 허용
  # cidr_blocks 대신 security_groups를 사용하여 특정 보안 그룹의 트래픽만 허용합니다
  ingress {                            # ingress: 인바운드 규칙입니다. ALB에서 전달되는 트래픽만 받습니다
    from_port       = 80               # from_port: HTTP 80번 포트입니다
    to_port         = 80               # to_port: 80번 포트만 허용합니다
    protocol        = "tcp"            # protocol: TCP 프로토콜입니다
    security_groups = [aws_security_group.alb.id]  # security_groups: IP 범위 대신 보안 그룹 ID로 접근을 제한합니다. ALB 보안 그룹에 속한 리소스(= ALB)에서 오는 트래픽만 허용합니다
  }

  # 아웃바운드 규칙: 모든 트래픽 허용
  # 앱 서버가 외부 API 호출, 패키지 다운로드 등을 할 수 있도록 나가는 트래픽은 모두 허용합니다
  egress {                             # egress: 아웃바운드 규칙입니다
    from_port   = 0                    # from_port: 모든 포트 시작
    to_port     = 0                    # to_port: 모든 포트 끝
    protocol    = "-1"                 # protocol: 모든 프로토콜 허용
    cidr_blocks = ["0.0.0.0/0"]        # cidr_blocks: 모든 IP로 나가는 트래픽 허용
  }

  tags = {                             # tags: 보안 그룹에 붙일 태그입니다
    Name = "app-sg"                    # Name 태그: AWS 콘솔에서 "app-sg"로 표시됩니다
  }
}

# ============================================
# DB(데이터베이스) 보안 그룹
# 앱 서버 보안 그룹에서 오는 MySQL(3306) 트래픽만 허용합니다.
# 데이터베이스는 가장 중요한 데이터를 보관하므로 접근을 최소한으로 제한합니다.
# 인터넷은 물론, ALB에서도 직접 접근할 수 없고 오직 앱 서버만 접근 가능합니다.
# ============================================
resource "aws_security_group" "db" {   # resource "aws_security_group" "db": DB(RDS)용 보안 그룹을 생성합니다. RDS 인스턴스에 적용됩니다
  name        = "db-sg"                # name: 보안 그룹 이름입니다
  description = "Security group for RDS"  # description: RDS용 보안 그룹임을 설명합니다
  vpc_id      = aws_vpc.main.id        # vpc_id: main VPC에 소속시킵니다

  # 인바운드 규칙: ALB 보안 그룹에서 오는 MySQL(3306) 트래픽만 허용
  # 참고: 실제로는 App SG를 참조하는 것이 더 적절할 수 있습니다
  ingress {                            # ingress: 인바운드 규칙입니다. 데이터베이스 접근을 제한합니다
    from_port       = 3306             # from_port: 3306은 MySQL 데이터베이스의 기본 포트입니다
    to_port         = 3306             # to_port: 3306 포트만 허용합니다
    protocol        = "tcp"            # protocol: TCP 프로토콜입니다. 데이터베이스 통신은 TCP를 사용합니다
    security_groups = [aws_security_group.alb.id]  # security_groups: ALB 보안 그룹에서 오는 트래픽만 허용합니다. (참고: 보안 강화를 위해 aws_security_group.app.id로 변경하는 것을 권장합니다)
  }

  # 아웃바운드 규칙: 모든 트래픽 허용
  egress {                             # egress: 아웃바운드 규칙입니다
    from_port   = 0                    # from_port: 모든 포트 시작
    to_port     = 0                    # to_port: 모든 포트 끝
    protocol    = "-1"                 # protocol: 모든 프로토콜 허용
    cidr_blocks = ["0.0.0.0/0"]        # cidr_blocks: 모든 IP로 나가는 트래픽 허용
  }

  tags = {                             # tags: 보안 그룹에 붙일 태그입니다
    Name = "db-sg"                     # Name 태그: AWS 콘솔에서 "db-sg"로 표시됩니다
  }
}
