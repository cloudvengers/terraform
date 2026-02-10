resource "aws_instance" "app_a" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_app_a.id
  vpc_security_group_ids = [aws_security_group.app.id]
  tags = {
    Name = "app-server-a"
  }
}
resource "aws_instance" "app_c" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_app_c.id
  vpc_security_group_ids = [aws_security_group.app.id]
  tags = {
    Name = "app-server-c"
  }
}
