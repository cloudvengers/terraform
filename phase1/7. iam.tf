# EC2 IAM Role 생성
resource "aws_iam_role" "ec2" {                                    # IAM Role 리소스 정의
  name = "ec2-app-role"                                            # Role 이름

  # Trust Policy (신뢰 정책) - EC2 서비스가 이 Role을 사용할 수 있도록 허용
  assume_role_policy = jsonencode({                                # JSON 형식으로 정책 정의
    Version = "2012-10-17"                                         # 정책 버전
    Statement = [                                                  # 정책 문장 배열
      {
        Action = "sts:AssumeRole"                                  # AssumeRole 작업 허용
        Effect = "Allow"                                           # 허용
        Principal = {                                              # 주체 (누가 이 Role을 사용할 수 있는지)
          Service = "ec2.amazonaws.com"                            # EC2 서비스
        }
      }
    ]
  })

  tags = {                                                         # 태그 맵
    Name = "ec2-app-role"                                          # Role 이름 태그
  }
}

# IAM Instance Profile 생성 (EC2에 Role을 연결하는 통로)
resource "aws_iam_instance_profile" "ec2" {                        # Instance Profile 리소스 정의
  name = "ec2-app-profile"                                         # Instance Profile 이름
  role = aws_iam_role.ec2.name                                     # 연결할 IAM Role 이름
}

# SSM Session Manager 정책 연결
resource "aws_iam_role_policy_attachment" "ssm" {                  # Role Policy Attachment 리소스 정의
  role = aws_iam_role.ec2.name                                     # 정책을 연결할 Role 이름
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" # AWS 관리형 정책 ARN (SSM 접근 권한)
}
