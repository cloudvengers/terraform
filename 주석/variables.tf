# ============================================
# 변수(Variable) 정의 파일
# 변수는 코드에서 반복적으로 사용되는 값을 한 곳에서 관리하기 위한 것입니다.
# 변수를 사용하면 값을 변경할 때 이 파일만 수정하면 되므로 유지보수가 편리합니다.
# 실제 값은 terraform.tfvars 파일에서 지정합니다.
# ============================================

# EC2 인스턴스에 사용할 AMI(Amazon Machine Image) ID 변수
# AMI는 EC2 서버를 만들 때 사용하는 운영체제 이미지입니다 (예: Amazon Linux, Ubuntu 등)
variable "ami_id" {                  # variable "ami_id": "ami_id"라는 이름의 변수를 선언합니다. 다른 파일에서 var.ami_id로 참조할 수 있습니다
  description = "AMI ID for EC2 instance"  # description: 이 변수가 무엇인지 설명하는 텍스트입니다. 문서화 목적으로 사용됩니다
  type        = string               # type: 이 변수의 데이터 타입입니다. string은 문자열(텍스트)을 의미합니다. AMI ID는 "ami-0e349888043265b96" 같은 문자열입니다
}

# EC2 인스턴스 타입(사양) 변수
# 인스턴스 타입은 서버의 CPU, 메모리 등 하드웨어 사양을 결정합니다
variable "instance_type" {           # variable "instance_type": EC2 인스턴스의 사양을 지정하는 변수입니다. var.instance_type으로 참조합니다
  description = "EC2 instance type"  # description: 이 변수의 용도를 설명합니다
  type        = string               # type: 문자열 타입입니다. "t2.micro", "t3.medium" 같은 값이 들어갑니다
  default     = "t2.micro"           # default: 기본값입니다. 별도로 값을 지정하지 않으면 "t2.micro"가 사용됩니다. t2.micro는 AWS 프리티어(무료)로 사용 가능한 가장 작은 인스턴스입니다
}
