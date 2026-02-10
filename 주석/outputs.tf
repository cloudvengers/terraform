# ============================================
# 출력값 (Outputs) 정의 파일
#
# output은 terraform apply 실행이 끝난 후 터미널에 중요한 정보를 자동으로 출력해주는 기능입니다.
# 매번 AWS 콘솔에 접속해서 확인할 필요 없이, 명령어 한 번으로 필요한 정보를 바로 볼 수 있습니다.
# terraform output 명령어로 언제든 다시 확인할 수 있습니다.
# ============================================

# ALB의 DNS 주소 출력 - 웹 브라우저에서 이 주소로 접속하면 서비스에 접근할 수 있습니다
output "alb_dns_name" {              # output "alb_dns_name": "alb_dns_name"이라는 이름의 출력값을 정의합니다. terraform apply 후 터미널에 표시됩니다
  description = "ALB DNS name"       # description: 이 출력값이 무엇인지 설명하는 텍스트입니다. 다른 사람이 봤을 때 이해하기 쉽도록 작성합니다
  value       = aws_alb.alb.dns_name # value: 실제 출력할 값입니다. alf.tf에서 만든 ALB의 DNS 주소를 가져옵니다. 예: "alb-123456.us-east-1.elb.amazonaws.com"
}

# VPC ID 출력 - 다른 리소스를 추가하거나 디버깅할 때 VPC ID가 필요한 경우가 많습니다
output "vpc_id" {                    # output "vpc_id": VPC의 고유 ID를 출력합니다
  description = "VPC ID"             # description: VPC ID 출력값에 대한 설명입니다
  value       = aws_vpc.main.id      # value: vpc.tf에서 만든 main VPC의 ID를 가져옵니다. 예: "vpc-0abc123def456"
}

# RDS 접속 엔드포인트 출력 - 앱에서 데이터베이스에 연결할 때 이 주소를 사용합니다
output "rds_endpoint" {              # output "rds_endpoint": RDS 데이터베이스의 접속 주소를 출력합니다
  description = "RDS endpoint"       # description: RDS 엔드포인트 출력값에 대한 설명입니다
  value       = aws_db_instance.main.endpoint  # value: rds.tf에서 만든 RDS 인스턴스의 엔드포인트를 가져옵니다. 예: "main-db.xxxx.us-east-1.rds.amazonaws.com:3306"
}
