# 1. VPC 생성
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main-vpc"
  }
}

# 2. 퍼블릭 서브넷 A 생성
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet-a"
  }
}

# 3. 퍼블릭 서브넷 C 생성
resource "aws_subnet" "public_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "public-subnet-c"
  }
}

# =================================================

# 4. 프라이빗 앱 서브넷 A 생성
resource "aws_subnet" "private_app_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-app-subnet-a"
  }
}

# 5. 프라이빗 앱 서브넷 C 생성
resource "aws_subnet" "private_app_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "private-app-subnet-c"
  }
}

# =================================================

# 6. 프라이빗 db 서브넷 A 생성
resource "aws_subnet" "private_db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-db-subnet-a"
  }
}

# 7. 프라이빗 db 서브넷 C 생성
resource "aws_subnet" "private_db_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-db-subnet-c"
  }
}