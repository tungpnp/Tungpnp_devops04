# File: terraform/modules/01-vpc/outputs.tf
# Mục đích: Xuất các giá trị ID tài nguyên (Outputs) để các module khác (Security, Database, EKS) có thể tái sử dụng

output "vpc_id" {
  description = "ID của mạng VPC vừa khởi tạo"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "Dải CIDR của mạng VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Danh sách ID của các Public Subnets (Dùng cho Application Load Balancer)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Danh sách ID của các Private Subnets (Dùng cho EKS Worker Nodes, RDS PostgreSQL và ElastiCache)"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID của Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# Xuất thêm danh sách ID của NAT Gateway (Trên Floci sẽ trả về mảng rỗng [], trên AWS Prod trả về danh sách nat-xxx)
output "nat_gateway_ids" {
  description = "Danh sách ID của các NAT Gateways (nếu bật enable_nat_gateway = true)"
  value       = aws_nat_gateway.main[*].id
}
