resource "aws_instance" "app_a" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_app_a.id
  vpc_security_group_ids = [aws_security_group.app.id]
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>App Server A</h1>" > /var/www/html/index.html
              EOF
  
  tags = {
    Name = "app-server-a"
  }
}
resource "aws_instance" "app_c" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_app_c.id
  vpc_security_group_ids = [aws_security_group.app.id]
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>App Server C</h1>" > /var/www/html/index.html
              EOF
  
  tags = {
    Name = "app-server-c"
  }
}
