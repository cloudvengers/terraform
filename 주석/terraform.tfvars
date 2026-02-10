# ============================================
# Terraform 변수 값 파일 (terraform.tfvars)
# variables.tf에서 선언한 변수들의 실제 값을 여기서 지정합니다.
# Terraform은 이 파일을 자동으로 읽어서 변수에 값을 할당합니다.
# 이 파일은 환경(개발/스테이징/운영)마다 다르게 설정할 수 있습니다.
# ============================================

ami_id = "ami-0e349888043265b96"     # ami_id 변수에 실제 AMI ID 값을 지정합니다. 이 AMI는 EC2 인스턴스를 생성할 때 사용할 운영체제 이미지입니다

# ============================================
# 아래는 참고용 주석입니다 (실제 실행되지 않음)
# AMI ID를 찾는 방법을 설명합니다
# ============================================
/*
# Amazon Linux 2 최신 AMI를 찾는 AWS CLI 명령어입니다
# --owners amazon: 아마존이 공식 제공하는 이미지만 검색합니다
# --filters: 이름 패턴으로 Amazon Linux 2 HVM x86_64 이미지를 필터링합니다
# --query: 결과를 생성일 기준으로 정렬하여 가장 최신 이미지의 ID만 출력합니다
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text

# Ubuntu 22.04 최신 AMI를 찾는 AWS CLI 명령어입니다
# --owners 099720109477: Canonical(Ubuntu 제작사)의 AWS 계정 ID입니다
# Ubuntu Jammy 22.04 LTS 버전의 최신 AMI를 검색합니다
aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text


3. Terraform data source 사용 (추천):
hcl
# ec2.tf에 추가하면 항상 최신 Amazon Linux 2 AMI를 자동으로 가져옵니다
# data 소스는 AWS에서 정보를 조회하는 읽기 전용 리소스입니다
data "aws_ami" "amazon_linux_2" {
  most_recent = true                 # 가장 최신 AMI를 선택합니다
  owners      = ["amazon"]          # 아마존 공식 이미지만 대상으로 합니다

  filter {                           # 검색 필터: 이름 패턴으로 Amazon Linux 2를 찾습니다
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 위 data source를 사용하는 예시입니다
# ami_id를 하드코딩하는 대신 data.aws_ami.amazon_linux_2.id로 항상 최신 AMI를 참조할 수 있습니다
resource "aws_instance" "app_a" {
  ami = data.aws_ami.amazon_linux_2.id
  ...
}
*/
