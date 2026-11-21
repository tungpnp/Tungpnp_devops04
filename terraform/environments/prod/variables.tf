# File: terraform/environments/prod/variables.tf
# Mục đích: Định nghĩa khuôn mẫu biến cho môi trường AWS Production (đối xứng 100% với Floci để dùng chung 7 Modules)

variable "aws_region" {
  type        = string
  description = "Region triển khai trên AWS Production (ví dụ: ap-southeast-1)"
}

variable "aws_profile" {
  type        = string
  description = "Tên AWS CLI Profile (ví dụ: prod-admin)"
}

variable "project_name" {
  type        = string
  description = "Tên định danh dự án"
}

variable "environment" {
  type        = string
  description = "Tên môi trường triển khai (prod)"
}

variable "vpc_cidr" {
  type        = string
  description = "Dải CIDR riêng của Production (10.40.0.0/16)"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Danh sách CIDR cho Public Subnets"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Danh sách CIDR cho Private Subnets"
}

variable "availability_zones" {
  type        = list(string)
  description = "Danh sách Availability Zones"
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Bật NAT Gateway cho Private EKS Worker Nodes"
}

variable "single_nat_gateway" {
  type        = bool
  description = "Tắt chế độ đơn (false) để mỗi AZ có 1 NAT Gateway độc lập (Multi-AZ HA)"
}

variable "enable_eks_tags" {
  type        = bool
  description = "Gắn nhãn Subnet cho AWS Load Balancer Controller"
}

variable "db_name" {
  type        = string
  description = "Tên Database PostgreSQL"
}

variable "db_username" {
  type        = string
  description = "Tên tài khoản quản trị PostgreSQL"
}

variable "db_password" {
  type        = string
  description = "Mật khẩu RDS Production (truyền qua TF_VAR_db_password hoặc CI/CD Secret)"
  sensitive   = true
}

variable "jwt_secret" {
  type        = string
  description = "Khóa ký JWT Secret Production (truyền qua TF_VAR_jwt_secret)"
  sensitive   = true
}

variable "recovery_window_in_days" {
  type        = number
  description = "Số ngày giữ bí mật trước khi xóa vĩnh viễn (Production dùng 30 ngày)"
}

variable "db_instance_class" {
  type        = string
  description = "Cấu hình máy chủ RDS Production (ví dụ: db.t3.medium)"
}

variable "db_allocated_storage" {
  type        = number
  description = "Dung lượng ổ cứng RDS (GB)"
}

variable "multi_az" {
  type        = bool
  description = "Bật Multi-AZ High Availability trên Production (true)"
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Luôn chụp Final Snapshot bảo toàn dữ liệu trên Production (false)"
}

variable "enable_elasticache" {
  type        = bool
  description = "Bật cụm ElastiCache Redis"
}

variable "redis_node_type" {
  type        = string
  description = "Loại node ElastiCache Redis Production"
}

variable "max_receive_count" {
  type        = number
  description = "Số lần retry trước khi đẩy vào Dead Letter Queue"
}

variable "ecr_repositories" {
  type        = list(string)
  description = "Danh sách các kho ECR"
}

variable "force_destroy_bucket" {
  type        = bool
  description = "Chặn xóa nhầm S3 Bucket trên Production (false)"
}

variable "cluster_name" {
  type        = string
  description = "Tên cụm Amazon EKS"
}

variable "kubernetes_version" {
  type        = string
  description = "Phiên bản Kubernetes của EKS"
}

variable "enable_eks" {
  type        = bool
  description = "Bật cụm EKS"
}

variable "enable_alb" {
  type        = bool
  description = "Bật Application Load Balancer"
}
