# SNS Topic: 알림을 보내는 채널 (CloudWatch 등이 여기로 알림 전송)
resource "aws_sns_topic" "alert" {
  name = "infra-alert-topic"

  tags = {
    Name = "infra-alert-topic"
  }
}

# SNS 구독: 위 Topic에 알림이 오면 이메일로 전달
# apply 후 해당 이메일로 확인 메일이 옴 -> "Confirm subscription" 클릭해야 활성화
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alert.arn  # 어떤 Topic을 구독할지
  protocol  = "email"                  # 전달 방식
  endpoint  = "cloudvengers@gmail.com" # 알림 받을 이메일 주소
}