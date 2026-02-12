# EC2가 사용할 IAM Role
resource "aws_iam_role" "ec2" {
  name = "ec2-app-role"

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

  tags = {
    Name = "ec2-app-role"
  }
}

# Instance Profile — EC2에 Role을 연결하는 통로
resource "aws_iam_instance_profile" "ec2" {
  name = "ec2-app-profile"
  role = aws_iam_role.ec2.name
}