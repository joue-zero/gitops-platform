output "vpc_id" { value = aws_vpc.main.id }
output "public_subnet_ids" { value = aws_subnet.public[*].id }
output "private_subnet_ids" {
  value      = aws_subnet.private[*].id
  depends_on = [aws_route_table_association.private, aws_route_table_association.public] # egress needs NAT and its public route
}
output "data_subnet_ids" { value = aws_subnet.data[*].id }
