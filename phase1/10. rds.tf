# DB Subnet Group 생성 (RDS가 사용할 서브넷 그룹)
resource "aws_db_subnet_group" "main" {                            # DB Subnet Group 리소스 정의
  name       = "main-db-subnet-group"                              # Subnet Group 이름
  subnet_ids = [aws_subnet.private_db_a.id, aws_subnet.private_db_c.id] # Private DB Subnet ID 목록 (다중 AZ)

  tags = {                                                         # 태그 맵
    Name = "main-db-subnet-group"                                  # Subnet Group 이름 태그
  }
}

# RDS MySQL 인스턴스 생성
resource "aws_db_instance" "main" {                                # RDS Instance 리소스 정의
  identifier             = "main-db"                               # DB 인스턴스 식별자
  engine                 = "mysql"                                 # 데이터베이스 엔진
  engine_version         = "8.0"                                   # 엔진 버전
  instance_class         = "db.t3.micro"                           # 인스턴스 클래스
  allocated_storage      = 20                                      # 할당된 스토리지 (GB)
  storage_type           = "gp3"                                   # 스토리지 타입 (General Purpose SSD v3)
  storage_encrypted      = true                                    # 스토리지 암호화 활성화
  db_name                = "mydb"                                  # 초기 데이터베이스 이름
  username               = "admin"                                 # 마스터 사용자 이름
  password               = "password123!"                          # 마스터 비밀번호 (Secrets Manager 교체 예정)
  db_subnet_group_name   = aws_db_subnet_group.main.name          # DB Subnet Group 이름
  vpc_security_group_ids = [aws_security_group.db.id]             # 보안 그룹 ID 목록
  skip_final_snapshot    = true                                    # 삭제 시 최종 스냅샷 생성 건너뛰기

  tags = {                                                         # 태그 맵
    Name = "main-rds"                                              # RDS 인스턴스 이름 태그
  }
}
