# File: terraform/environments/prod/outputs.tf
# Mục đích: Xuất toàn bộ thông số hạ tầng Production sau khi apply thành công trên AWS Thật

output "vpc_id" {
  description = "ID của VPC Production"
  value       = module.vpc.vpc_id
}

output "nat_gateway_ids" {
  description = "ID của 2 NAT Gateways Multi-AZ"
  value       = module.vpc.nat_gateway_ids
}

output "alb_sg_id" {
  description = "ID của ALB Security Group"
  value       = module.security.alb_sg_id
}

output "app_sg_id" {
  description = "ID của App/EKS Security Group"
  value       = module.security.app_sg_id
}

output "db_sg_id" {
  description = "ID của DB Security Group"
  value       = module.security.db_sg_id
}

output "app_iam_role_arn" {
  description = "ARN của IAM Role Least-Privilege"
  value       = module.security.app_iam_role_arn
}

output "rds_endpoint" {
  description = "Endpoint RDS PostgreSQL Multi-AZ"
  value       = module.database.rds_endpoint
}

output "redis_endpoint" {
  description = "Endpoint ElastiCache Redis"
  value       = module.database.redis_endpoint
}

output "order_queue_url" {
  description = "URL hàng đợi SQS"
  value       = module.messaging.order_queue_url
}

output "s3_bucket_id" {
  description = "Tên S3 Bucket Production"
  value       = module.storage.s3_bucket_id
}

output "eks_cluster_endpoint" {
  description = "API Endpoint của Amazon EKS Production"
  value       = module.eks_and_ingress.eks_cluster_endpoint
}

output "alb_dns_name" {
  description = "DNS Name công khai của Application Load Balancer"
  value       = module.eks_and_ingress.alb_dns_name
}
