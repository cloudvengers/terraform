# ============================================
# ALB (Application Load Balancer) 및 관련 리소스 설정
#
# ALB는 들어오는 웹 트래픽을 여러 서버에 골고루 분배하는 로드밸런서입니다.
# 마치 식당 입구의 안내원이 손님을 빈 테이블로 안내하는 것과 같습니다.
#
# [구성 요소]
# 1. ALB: 트래픽을 받아서 분배하는 로드밸런서 본체
# 2. 타겟 그룹: 트래픽을 받을 서버(EC2) 목록과 헬스 체크 설정
# 3. 타겟 등록: 타겟 그룹에 실제 서버를 등록
# 4. 리스너: ALB가 어떤 포트/프로토콜로 트래픽을 수신할지 설정
#
# [트래픽 흐름]
# 사용자 → ALB(리스너:80) → 타겟 그룹 → 앱 서버 A 또는 C
# ============================================

# ALB(Application Load Balancer) 생성
# 퍼블릭 서브넷에 배치되어 인터넷에서 들어오는 트래픽을 받습니다
resource "aws_alb" "alb" {             # resource "aws_alb" "alb": ALB를 생성합니다. aws_alb.alb로 참조합니다
  name               = "alb"          # name: ALB의 이름입니다. AWS 콘솔과 DNS 이름에 사용됩니다
  internal           = false           # internal: false면 인터넷 대상(외부 공개) ALB, true면 내부 전용 ALB입니다. 웹 서비스이므로 false로 설정합니다
  load_balancer_type = "application"   # load_balancer_type: 로드밸런서 타입입니다. "application"은 HTTP/HTTPS 트래픽을 처리하는 7계층(L7) 로드밸런서입니다
  security_groups    = [aws_security_group.alb.id]                          # security_groups: ALB에 적용할 보안 그룹입니다. security.tf에서 만든 ALB 보안 그룹(80, 443 허용)을 적용합니다
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_c.id]    # subnets: ALB를 배치할 서브넷 목록입니다. 고가용성을 위해 2개 이상의 가용영역에 걸쳐 배치해야 합니다

  tags = {                             # tags: ALB에 붙일 태그입니다
    Name = "alb"                       # Name 태그: AWS 콘솔에서 "alb"로 표시됩니다
  }
}

# ============================================
# 타겟 그룹 - ALB가 트래픽을 전달할 대상(서버) 그룹
# 타겟 그룹에 등록된 서버들에게 트래픽이 분배됩니다.
# 헬스 체크를 통해 정상적인 서버에만 트래픽을 보냅니다.
# ============================================
resource "aws_lb_target_group" "app" { # resource "aws_lb_target_group" "app": 타겟 그룹을 생성합니다. ALB가 트래픽을 보낼 서버 목록을 관리합니다
  name     = "tg"                      # name: 타겟 그룹의 이름입니다
  port     = 80                        # port: 타겟(서버)이 트래픽을 수신할 포트입니다. 앱 서버의 80번 포트로 전달합니다
  protocol = "HTTP"                    # protocol: 타겟과 통신할 프로토콜입니다. HTTP를 사용합니다
  vpc_id   = aws_vpc.main.id           # vpc_id: 타겟 그룹이 속할 VPC입니다. 타겟(EC2)이 있는 VPC와 같아야 합니다

  # 헬스 체크 설정 - 서버가 정상적으로 동작하는지 주기적으로 확인합니다
  # 비정상 서버에는 트래픽을 보내지 않아 사용자에게 안정적인 서비스를 제공합니다
  health_check {                       # health_check: 헬스 체크(건강 검진) 설정 블록입니다. ALB가 주기적으로 서버 상태를 확인합니다
    healthy_threshold   = 2            # healthy_threshold: 연속 2번 성공하면 "정상" 상태로 판정합니다. 숫자가 작을수록 빨리 정상으로 복귀합니다
    unhealthy_threshold = 2            # unhealthy_threshold: 연속 2번 실패하면 "비정상" 상태로 판정합니다. 비정상 서버에는 트래픽을 보내지 않습니다
    timeout             = 5            # timeout: 헬스 체크 응답을 5초 동안 기다립니다. 5초 안에 응답이 없으면 실패로 간주합니다
    interval            = 30           # interval: 30초마다 헬스 체크를 수행합니다. 즉, 30초에 한 번씩 서버 상태를 확인합니다
  }

  tags = {                             # tags: 타겟 그룹에 붙일 태그입니다
    Name = "tg"                        # Name 태그: AWS 콘솔에서 "tg"로 표시됩니다
  }
}

# ============================================
# 타겟 그룹에 앱 서버 등록
# 타겟 그룹에 실제 EC2 인스턴스를 등록해야 ALB가 트래픽을 전달할 수 있습니다.
# ============================================

# 타겟 그룹에 앱 서버 A 등록
resource "aws_lb_target_group_attachment" "app_a" {  # resource "aws_lb_target_group_attachment": 타겟 그룹에 서버를 등록하는 리소스입니다
  target_group_arn = aws_lb_target_group.app.arn     # target_group_arn: 서버를 등록할 타겟 그룹의 ARN(고유 식별자)입니다. 위에서 만든 타겟 그룹을 지정합니다
  target_id        = aws_instance.app_a.id           # target_id: 등록할 서버(EC2 인스턴스)의 ID입니다. ec2.tf에서 만든 앱 서버 A를 등록합니다
  port             = 80                              # port: 이 서버가 트래픽을 수신할 포트입니다. 80번 포트(HTTP)로 트래픽을 전달합니다
}

# 타겟 그룹에 앱 서버 C 등록
resource "aws_lb_target_group_attachment" "app_c" {  # resource "aws_lb_target_group_attachment": 두 번째 서버를 타겟 그룹에 등록합니다
  target_group_arn = aws_lb_target_group.app.arn     # target_group_arn: 같은 타겟 그룹에 등록합니다. 이제 이 타겟 그룹에는 서버 2대가 등록됩니다
  target_id        = aws_instance.app_c.id           # target_id: 앱 서버 C를 등록합니다. ALB가 서버 A와 C에 트래픽을 골고루 분배합니다
  port             = 80                              # port: 80번 포트로 트래픽을 전달합니다
}

# ============================================
# 리스너 - ALB가 트래픽을 수신하는 규칙
# ALB의 특정 포트로 들어오는 요청을 어떻게 처리할지 정의합니다.
# 여기서는 80번 포트(HTTP)로 들어오는 요청을 타겟 그룹으로 전달(forward)합니다.
# ============================================
resource "aws_lb_listener" "http" {    # resource "aws_lb_listener" "http": ALB 리스너를 생성합니다. ALB가 어떤 포트에서 트래픽을 수신할지 정의합니다
  load_balancer_arn = aws_alb.alb.arn  # load_balancer_arn: 이 리스너를 연결할 ALB의 ARN입니다. 위에서 만든 ALB에 연결합니다
  port              = 80               # port: ALB가 트래픽을 수신할 포트입니다. 80번 포트(HTTP)에서 요청을 받습니다
  protocol          = "HTTP"           # protocol: 수신할 프로토콜입니다. HTTP 프로토콜을 사용합니다

  default_action {                     # default_action: 수신한 트래픽을 어떻게 처리할지 정의합니다. 기본 동작을 설정합니다
    type             = "forward"       # type: 동작 유형입니다. "forward"는 트래픽을 타겟 그룹으로 전달(포워딩)한다는 뜻입니다
    target_group_arn = aws_lb_target_group.app.arn  # target_group_arn: 트래픽을 전달할 타겟 그룹입니다. 위에서 만든 앱 타겟 그룹으로 보냅니다
  }
}
