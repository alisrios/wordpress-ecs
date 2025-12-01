resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = var.vpc.private_route_table_name
    }
  )
}

resource "aws_route_table_association" "private" {
  count = length(var.vpc.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
