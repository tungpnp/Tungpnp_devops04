# File: terraform/environments/floci/outputs.tf
# Mục đích: Xuất toàn bộ thông số hạ tầng của 7 Modules sau khi triển khai thành công lên Floci

# --- 01-vpc ---
output "vpc_id" {
  description = "ID của mạng VPC trên Floci"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Danh sách Public Subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Danh sách Private Subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# --- 02-security ---
output "alb_sg_id" {
  description = "ID của Security Group tầng ALB"
  value       = module.security.alb_sg_id
}

output "app_sg_id" {
  description = "ID của Security Group tầng App/K8s"
  value       = module.security.app_sg_id
}

output "db_sg_id" {
  description = "ID của Security Group tầng Database"
  value       = module.security.db_sg_id
}

output "app_iam_role_arn" {
  description = "ARN của IAM Role Least-Privilege cấp cho ứng dụng"
  value       = module.security.app_iam_role_arn
}

# --- 03-secrets ---
output "db_secret_arn" {
  description = "ARN Secret chứa thông tin DB trên Secrets Manager"
  value       = module.secrets.db_secret_arn
}

output "jwt_ssm_name" {
  description = "Tên tham số JWT Secret trên SSM Parameter Store"
  value       = module.secrets.jwt_ssm_name
}

# --- 04-database ---
output "rds_endpoint" {
  description = "Endpoint kết nối Amazon RDS PostgreSQL"
  value       = module.database.rds_endpoint
}

output "redis_endpoint" {
  description = "Endpoint kết nối ElastiCache Redis"
  value       = module.database.redis_endpoint
}

# --- 05-messaging ---
output "sns_topic_arn" {
  description = "ARN của SNS Topic Trading Events"
  value       = module.messaging.sns_topic_arn
}

output "order_queue_url" {
  description = "URL của SQS Order Queue"
  value       = module.messaging.order_queue_url
}

# --- 06-storage ---
output "s3_bucket_id" {
  description = "Tên S3 Bucket lưu báo cáo"
  value       = module.storage.s3_bucket_id
}

output "ecr_repository_urls" {
  description = "Bản đồ URL các kho Docker Image ECR"
  value       = module.storage.ecr_repository_urls
}

# --- 07-eks-and-ingress ---
output "eks_cluster_name" {
  description = "Tên cụm Amazon EKS"
  value       = module.eks_and_ingress.eks_cluster_name
}

output "eks_cluster_endpoint" {
  description = "API Endpoint của cụm EKS"
  value       = module.eks_and_ingress.eks_cluster_endpoint
}

output "alb_dns_name" {
  description = "DNS Name công khai của Application Load Balancer"
  value       = module.eks_and_ingress.alb_dns_name
}
