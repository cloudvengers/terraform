output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_alb.alb.dns_name
}
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
}
