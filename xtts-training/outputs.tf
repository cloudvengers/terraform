output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.xtts_training.id
}

output "instance_public_ip" {
  description = "Public IP address"
  value       = aws_instance.xtts_training.public_ip
}

output "ssh_command" {
  description = "SSH connection command"
  value       = "ssh -i ~/.ssh/xtts-training-key ubuntu@${aws_instance.xtts_training.public_ip}"
}

output "my_ip" {
  description = "Your current IP (allowed in security group)"
  value       = "${chomp(data.http.my_ip.response_body)}/32"
}
