# Application Load Balancer 생성
resource "aws_lb" "app" {                                          # ALB 리소스 정의
  name               = "app-alb"                                   # ALB 이름
  internal           = false                                       # 인터넷 연결 (false = 외부 접근 가능)
  load_balancer_type = "application"                               # 로드 밸런서 타입 (Application)
  security_groups    = [aws_security_group.alb.id]                # 보안 그룹 ID 목록
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_c.id] # Public Subnet ID 목록 (다중 AZ)

  tags = {                                                         # 태그 맵
    Name = "app-alb"                                               # ALB 이름 태그
  }
}

# Target Group 생성 (ALB가 트래픽을 전달할 대상 그룹)
resource "aws_lb_target_group" "app" {                             # Target Group 리소스 정의
  name     = "app-tg"                                              # Target Group 이름
  port     = 80                                                    # 대상 포트
  protocol = "HTTP"                                                # 프로토콜
  vpc_id   = aws_vpc.main.id                                       # VPC ID

  # Health Check 설정
  health_check {                                                   # 헬스체크 블록
    path                = "/"                                      # 헬스체크 경로
    healthy_threshold   = 2                                        # 정상 판정 임계값 (연속 성공 횟수)
    unhealthy_threshold = 3                                        # 비정상 판정 임계값 (연속 실패 횟수)
    timeout             = 5                                        # 타임아웃 (초)
    interval            = 30                                       # 헬스체크 간격 (초)
  }

  tags = {                                                         # 태그 맵
    Name = "app-tg"                                                # Target Group 이름 태그
  }
}

# ALB Listener 생성 (들어오는 요청을 처리하는 규칙)
resource "aws_lb_listener" "http" {                                # Listener 리소스 정의
  load_balancer_arn = aws_lb.app.arn                               # ALB ARN
  port              = 80                                           # 리스너 포트
  protocol          = "HTTP"                                       # 프로토콜

  # 기본 동작 설정
  default_action {                                                 # 기본 액션 블록
    type             = "forward"                                   # 액션 타입 (forward = 전달)
    target_group_arn = aws_lb_target_group.app.arn                 # 전달할 Target Group ARN
  }
}
