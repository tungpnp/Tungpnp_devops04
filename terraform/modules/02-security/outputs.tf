# File: terraform/modules/02-security/outputs.tf
# Mục đích: Xuất mã ID của 3 lớp khiên Security Groups và ARN của IAM Role để các module tiếp theo (RDS, EKS, ALB) sử dụng

output "alb_sg_id" {
  description = "ID của Security Group tầng Cửa ngõ (ALB - Mở cổng 80/443)"
  value       = aws_security_group.alb.id
}

output "app_sg_id" {
  description = "ID của Security Group tầng Ứng dụng K8s (Frontend 80, API Gateway 3001, Backend Java 8080)"
  value       = aws_security_group.app.id
}

output "db_sg_id" {
  description = "ID của Security Group tầng Dữ liệu (RDS Postgres 5432 & ElastiCache Redis 6379)"
  value       = aws_security_group.db.id
}

output "app_iam_role_arn" {
  description = "ARN của IAM Role dành cho ứng dụng đọc Secrets Manager & SSM"
  value       = aws_iam_role.app.arn
}

output "app_iam_role_name" {
  description = "Tên của IAM Role dành cho ứng dụng"
  value       = aws_iam_role.app.name
}

