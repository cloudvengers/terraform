resource "aws_default_route_table" "example" {
  default_route_table_id = aws_vpc.example.default_route_table_id

  route = [] #관리하는 라우트를 비움

  tags = {
    Name = "example"
  }
}