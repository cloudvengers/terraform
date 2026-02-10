# ============================================
# RDS (Relational Database Service) 설정
#
# RDS는 AWS에서 관리하는 관계형 데이터베이스 서비스입니다.
# 직접 DB 서버를 설치하고 관리할 필요 없이, AWS가 백업, 패치, 모니터링을 대신 해줍니다.
# 여기서는 MySQL 데이터베이스를 프라이빗 DB 서브넷에 생성합니다.
#
# [접근 경로]
# 앱 서버(EC2) → DB 보안 그룹(3306 허용) → RDS MySQL
# 인터넷에서는 직접 접근할 수 없습니다 (프라이빗 서브넷 + 보안 그룹으로 보호)
# ============================================

# RDS용 서브넷 그룹 - RDS가 사용할 서브넷들을 묶어주는 그룹
# RDS는 고가용성을 위해 최소 2개 이상의 가용영역(AZ)에 걸친 서브넷이 필요합니다
resource "aws_db_subnet_group" "main" {  # resource "aws_db_subnet_group" "main": DB 서브넷 그룹을 생성합니다. RDS 인스턴스 생성 시 이 그룹을 참조합니다
  name       = "main-db-subnet-group"    # name: 서브넷 그룹의 이름입니다. RDS 생성 시 이 이름으로 참조합니다
  subnet_ids = [aws_subnet.private_db_a.id, aws_subnet.private_db_c.id]  # subnet_ids: 이 그룹에 포함할 서브넷 목록입니다. AZ-a와 AZ-c의 프라이빗 DB 서브넷 2개를 포함합니다

  tags = {                               # tags: 서브넷 그룹에 붙일 태그입니다
    Name = "main-db-subnet-group"        # Name 태그: AWS 콘솔에서 "main-db-subnet-group"으로 표시됩니다
  }
}

# ============================================
# RDS MySQL 인스턴스 생성
# 실제 데이터베이스 서버를 생성합니다.
# 프라이빗 DB 서브넷에 배치되어 인터넷에서 접근할 수 없습니다.
# ============================================
resource "aws_db_instance" "main" {    # resource "aws_db_instance" "main": RDS 데이터베이스 인스턴스를 생성합니다. 이것이 실제 DB 서버입니다
  identifier             = "main-db"   # identifier: RDS 인스턴스의 고유 식별자입니다. AWS 내에서 이 이름으로 DB를 구분합니다. 리전 내에서 유일해야 합니다
  engine                 = "mysql"     # engine: 사용할 데이터베이스 엔진입니다. "mysql"은 세계에서 가장 많이 사용되는 오픈소스 관계형 DB입니다. (다른 옵션: postgres, mariadb 등)
  engine_version         = "8.0"       # engine_version: MySQL 엔진의 버전입니다. 8.0은 최신 안정 버전으로 JSON 지원, 성능 개선 등이 포함되어 있습니다
  instance_class         = "db.t3.micro"  # instance_class: DB 인스턴스의 사양(CPU, 메모리)입니다. db.t3.micro는 vCPU 2개, 메모리 1GB로 프리티어 사용 가능한 가장 작은 사양입니다
  allocated_storage      = 20          # allocated_storage: 할당할 스토리지 용량(GB)입니다. 20GB의 디스크 공간을 DB에 할당합니다
  storage_type           = "gp3"       # storage_type: 스토리지 타입입니다. "gp3"는 범용 SSD로 가격 대비 성능이 좋습니다. (다른 옵션: gp2, io1, io2 등)
  db_name                = "mydb"      # db_name: RDS 생성 시 자동으로 만들어질 초기 데이터베이스 이름입니다. 이 이름으로 DB에 접속합니다
  username               = "admin"     # username: 데이터베이스 마스터(관리자) 사용자 이름입니다. DB에 접속할 때 이 계정을 사용합니다
  password               = "password123!"  # password: 마스터 사용자의 비밀번호입니다. ⚠️ 주의: 실제 운영 환경에서는 코드에 비밀번호를 직접 쓰지 말고 AWS Secrets Manager를 사용하세요!
  db_subnet_group_name   = aws_db_subnet_group.main.name   # db_subnet_group_name: 위에서 만든 DB 서브넷 그룹을 지정합니다. RDS가 이 서브넷 그룹의 서브넷에 배치됩니다
  vpc_security_group_ids = [aws_security_group.db.id]       # vpc_security_group_ids: 적용할 보안 그룹입니다. security.tf에서 만든 DB 보안 그룹을 적용하여 앱 서버에서만 접근 가능하게 합니다
  skip_final_snapshot    = true        # skip_final_snapshot: true면 DB 삭제 시 최종 스냅샷(백업)을 생성하지 않습니다. 테스트 환경에서만 true로 설정하세요. 운영 환경에서는 false로 하여 데이터를 보호해야 합니다

  tags = {                             # tags: RDS 인스턴스에 붙일 태그입니다
    Name = "main-rds"                  # Name 태그: AWS 콘솔에서 "main-rds"로 표시됩니다
  }
}
