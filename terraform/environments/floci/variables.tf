# File: terraform/environments/floci/variables.tf
# Mục đích: Định nghĩa khuôn mẫu biến đầu vào cho môi trường Floci (liên kết trọn bộ 7 Modules)
# Lưu ý: KHÔNG chứa giá trị nhạy cảm; mật khẩu được truyền qua TF_VAR_* hoặc tfvars cục bộ ngoài Git

variable "aws_region" {
  type        = string
  description = "Region mặc định của AWS/Floci (ví dụ: ap-southeast-1)"
}

variable "aws_profile" {
  type        = string
  description = "Tên Profile trong ~/.aws/credentials (ví dụ: floci)"
}

variable "floci_endpoint" {
  type        = string
  description = "Địa chỉ Endpoint của bộ giả lập Floci (mặc định: http://localhost:4566)"
}

variable "project_name" {
  type        = string
  description = "Tên định danh dự án (ví dụ: tungpnp-trading)"
}

variable "environment" {
  type        = string
  description = "Tên môi trường triển khai (floci)"
}

# --- Tham số cho Module 01-vpc ---
variable "vpc_cidr" {
  type        = string
  description = "Dải CIDR của VPC"
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
  description = "Bật/tắt NAT Gateway"
}

variable "single_nat_gateway" {
  type        = bool
  description = "Dùng 1 NAT Gateway chung hay Multi-AZ"
}

variable "enable_eks_tags" {
  type        = bool
  description = "Tự động gắn nhãn Subnet cho Kubernetes Load Balancer Controller"
}

# --- Tham số cho Module 03-secrets & 04-database ---
variable "db_name" {
  type        = string
  description = "Tên Database PostgreSQL khởi tạo"
}

variable "db_username" {
  type        = string
  description = "Tên tài khoản quản trị PostgreSQL"
}

variable "db_password" {
  type        = string
  description = "Mật khẩu Database PostgreSQL (truyền qua TF_VAR_db_password)"
  sensitive   = true
}

variable "jwt_secret" {
  type        = string
  description = "Khóa ký JWT Secret >= 32 ký tự (truyền qua TF_VAR_jwt_secret)"
  sensitive   = true
}

variable "recovery_window_in_days" {
  type        = number
  description = "Số ngày giữ bí mật trong Secrets Manager khi xóa (Floci = 0)"
}

variable "db_instance_class" {
  type        = string
  description = "Cấu hình instance RDS PostgreSQL"
}

variable "db_allocated_storage" {
  type        = number
  description = "Dung lượng ổ cứng RDS (GB)"
}

variable "multi_az" {
  type        = bool
  description = "Bật Multi-AZ cho RDS (Floci = false, Prod = true)"
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Bỏ qua snapshot cuối khi xóa RDS"
}

variable "enable_elasticache" {
  type        = bool
  description = "Công tắc bật/tắt ElastiCache Redis"
}

variable "redis_node_type" {
  type        = string
  description = "Loại node ElastiCache Redis"
}

# --- Tham số cho Module 05-messaging ---
variable "max_receive_count" {
  type        = number
  description = "Số lần retry trước khi đẩy vào Dead Letter Queue"
}

# --- Tham số cho Module 06-storage ---
variable "ecr_repositories" {
  type        = list(string)
  description = "Danh sách tên các kho Docker Image trên Amazon ECR"
}

variable "force_destroy_bucket" {
  type        = bool
  description = "Cho phép xóa S3 Bucket khi destroy trên môi trường lab Floci"
}

# --- Tham số cho Module 07-eks-and-ingress ---
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
  description = "Công tắc bật/tắt tài nguyên AWS EKS"
}

variable "enable_alb" {
  type        = bool
  description = "Công tắc bật/tắt tài nguyên AWS ALB"
}
