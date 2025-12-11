provider "aws" {
  region     = "us-east-1"
  access_key = ""
  secret_key = ""
}

resource "aws_instance" "example" {
    ami         = "ami-08d7aabbb50c2c24e"
    instance_type = "t3.micro"

    tags = {
      Name = "myec2"
    }
}