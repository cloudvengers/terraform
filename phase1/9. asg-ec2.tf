# Launch Template
resource "aws_launch_template" "app" {                             # Launch Template 리소스 정의
  name                   = "app-launch-template"                   # Launch Template 이름
  image_id               = "ami-0c1fe732b5494dc14"                 # Amazon Linux 2023 AMI ID (고정)
  instance_type          = "t3.micro"                              # 인스턴스 타입
  vpc_security_group_ids = [aws_security_group.app.id]            # 보안 그룹 ID 목록

  # IAM Instance Profile 설정
  iam_instance_profile {                                           # IAM Instance Profile 블록
    name = aws_iam_instance_profile.ec2.name                       # IAM Instance Profile 이름
  }

  # IMDSv2 설정 (인스턴스 메타데이터 보안 강화)
  metadata_options {                                               # 메타데이터 옵션 블록
    http_endpoint = "enabled"                                      # 메타데이터 서비스 활성화
    http_tokens   = "required"                                     # IMDSv2 토큰 필수 (보안 강화)
  }

  # 인스턴스 초기화 스크립트 (User Data를 Base64로 인코딩)
  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello from $(hostname)</h1>" > /var/www/html/index.html
  EOF
  )

  # 인스턴스 태그 설정
  tag_specifications {                                             # 태그 사양 블록
    resource_type = "instance"                                     # 태그를 적용할 리소스 타입
    tags = {                                                       # 태그 맵
      Name = "app-server"                                          # 인스턴스 이름 태그
    }
  }

  # Launch Template 자체 태그
  tags = {                                                         # Launch Template 태그 맵
    Name = "app-launch-template"                                   # Launch Template 이름 태그
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {                           # Auto Scaling Group 리소스 정의
  name                      = "app-asg"                            # ASG 이름
  min_size                  = 2                                    # 최소 인스턴스 수
  max_size                  = 4                                    # 최대 인스턴스 수
  desired_capacity          = 2                                    # 초기 인스턴스 수
  vpc_zone_identifier       = [aws_subnet.private_app_a.id, aws_subnet.private_app_c.id] # 인스턴스를 배치할 서브넷 목록
  target_group_arns         = [aws_lb_target_group.app.arn]       # 연결할 ALB Target Group ARN
  health_check_type         = "ELB"                                # 헬스체크 타입 (ELB 기반)
  health_check_grace_period = 300                                  # 헬스체크 유예 시간 (초)

  # Launch Template 설정
  launch_template {                                                # Launch Template 블록
    id      = aws_launch_template.app.id                           # Launch Template ID
    version = "$Latest"                                            # 최신 버전 사용
  }

  # 인스턴스 태그 설정
  tag {                                                            # 태그 블록
    key                 = "Name"                                   # 태그 키
    value               = "app-server"                             # 태그 값
    propagate_at_launch = true                                     # 인스턴스 시작 시 태그 전파
  }
}

# Auto Scaling Policy
resource "aws_autoscaling_policy" "cpu_target" {                   # Auto Scaling Policy 리소스 정의
  name                   = "cpu-target-tracking"                   # 정책 이름
  autoscaling_group_name = aws_autoscaling_group.app.name         # 적용할 ASG 이름
  policy_type            = "TargetTrackingScaling"                 # 정책 타입 (Target Tracking)

  # Target Tracking 설정
  target_tracking_configuration {                                  # Target Tracking 구성 블록
    predefined_metric_specification {                              # 사전 정의된 메트릭 사양 블록
      predefined_metric_type = "ASGAverageCPUUtilization"          # 메트릭 타입 (평균 CPU 사용률)
    }
    target_value = 70.0                                            # 목표 CPU 사용률 (%)
  }
}
