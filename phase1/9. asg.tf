# =============================================
# 9. ASG (Auto Scaling Group)
#
# ASG란?
# EC2 인스턴스를 자동으로 늘리고 줄이는 서비스.
# 트래픽이 많아지면 EC2를 추가하고, 줄어들면 제거해서
# 항상 적절한 수의 서버를 유지한다.
#
# 이 파일의 구성:
# 1) AMI 데이터 소스 — 최신 Amazon Linux 2023 AMI 자동 조회
# 2) Launch Template — EC2 인스턴스의 설정 템플릿
# 3) Auto Scaling Group — EC2 자동 증감 그룹
# 4) Scaling 정책 — CPU 70% 기준 자동 스케일링
# =============================================

# 최신 Amazon Linux 2023 AMI를 자동으로 가져오는 데이터 소스
data "aws_ami" "amazon_linux" {
  most_recent = true       # 가장 최신 AMI를 선택
  owners      = ["amazon"] # Amazon 공식 AMI만 검색

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"] # Amazon Linux 2023, x86_64
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"] # HVM 가상화 타입만
  }
}

# =============================================
# Launch Template — EC2 설정 템플릿 (AMI, 타입, 보안그룹 등)
# =============================================
resource "aws_launch_template" "app" {
  name          = "app-launch-template"
  image_id      = data.aws_ami.amazon_linux.id # 최신 Amazon Linux 2023
  instance_type = "t3.micro"                   # 테스트용 소형 인스턴스

  vpc_security_group_ids = [aws_security_group.app.id] # App 보안그룹 (ALB→80만 허용)

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name # iam.tf의 Instance Profile
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2 필수 (보안 강화)
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello from $(hostname)</h1>" > /var/www/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "app-server"
    }
  }

  tags = {
    Name = "app-launch-template"
  }
}

# =============================================
# Auto Scaling Group — EC2 자동 증감 그룹
# =============================================
resource "aws_autoscaling_group" "app" {
  name             = "app-asg"
  min_size         = 2    # 최소 2개 유지
  max_size         = 4    # 최대 4개까지
  desired_capacity = 2    # 초기 2개
  vpc_zone_identifier = [ # Private App 서브넷에 배치
    aws_subnet.private_app_a.id,
    aws_subnet.private_app_c.id
  ]
  target_group_arns         = [aws_lb_target_group.app.arn] # ALB Target Group에 자동 등록
  health_check_type         = "ELB"                         # ALB 헬스체크 사용
  health_check_grace_period = 300                           # 부팅 후 5분 유예

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "app-server"
    propagate_at_launch = true # EC2 생성 시 태그 자동 적용
  }
}

# =============================================
# Scaling 정책 — CPU 70% 기준 Target Tracking
# =============================================
resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization" # 평균 CPU 사용률
    }
    target_value = 70.0 # 70% 유지 목표
  }
}
