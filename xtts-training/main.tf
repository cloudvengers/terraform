terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# 현재 IP 가져오기
data "http" "my_ip" {
  url = "https://ifconfig.me/ip"
}

# 기본 VPC
data "aws_vpc" "default" {
  default = true
}

# 보안 그룹
resource "aws_security_group" "xtts_training" {
  name        = "xtts-training-sg"
  description = "Security group for XTTS training instance"
  vpc_id      = data.aws_vpc.default.id

  # SSH 접근 (내 IP만)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
    description = "SSH from my IP"
  }

  # 아웃바운드 전체 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "xtts-training-sg"
  }
}

# IAM 역할 (S3 접근용)
resource "aws_iam_role" "xtts_training" {
  name = "xtts-training-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_access" {
  name = "s3-access"
  role = aws_iam_role.xtts_training.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::voice-training-new",
          "arn:aws:s3:::voice-training-new/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "xtts_training" {
  name = "xtts-training-profile"
  role = aws_iam_role.xtts_training.name
}

# 최신 Deep Learning AMI 찾기
data "aws_ami" "deep_learning" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 22.04)*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 키페어 (기존 키 사용 또는 새로 생성)
resource "aws_key_pair" "xtts_training" {
  key_name   = "xtts-training-key"
  public_key = var.ssh_public_key
}

# EC2 인스턴스
resource "aws_instance" "xtts_training" {
  ami                    = data.aws_ami.deep_learning.id
  instance_type          = var.instance_type
  key_name              = aws_key_pair.xtts_training.key_name
  iam_instance_profile  = aws_iam_instance_profile.xtts_training.name
  vpc_security_group_ids = [aws_security_group.xtts_training.id]

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "xtts-training"
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "XTTS Training Instance Ready"
              EOF
}
