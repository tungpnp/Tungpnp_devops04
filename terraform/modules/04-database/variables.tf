# File: terraform/modules/04-database/variables.tf
# Mục đích: Định nghĩa tham số đầu vào cho Module 04-database (Amazon RDS PostgreSQL & ElastiCache Redis)

variable "project_name" {
  type        = string
  description = "Tên định danh dự án (ví dụ: tungpnp-trading)"
}

variable "environment" {
  type        = string
  description = "Tên môi trường triển khai (floci, local, dev, staging, prod, dr)"

  validation {
    condition     = contains(["floci", "local", "dev", "staging", "prod", "dr"], var.environment)
    error_message = "Giá trị environment phải nằm trong danh sách chuẩn: floci, local, dev, staging, prod, dr."
  }
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Danh sách Private Subnet IDs từ Module 01-vpc dùng để đặt Database an toàn"

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "RDS DB Subnet Group yêu cầu tối thiểu 2 Private Subnets trên 2 AZ khác nhau."
  }
}

variable "db_sg_id" {
  type        = string
  description = "ID của Security Group tầng Data (db-sg) từ Module 02-security"

  validation {
    condition     = length(var.db_sg_id) > 3 && substr(var.db_sg_id, 0, 3) == "sg-"
    error_message = "db_sg_id phải là mã Security Group hợp lệ bắt đầu bằng 'sg-'."
  }
}

variable "db_name" {
  type        = string
  description = "Tên cơ sở dữ liệu PostgreSQL khởi tạo ban đầu (ví dụ: userdb)"
}

variable "db_username" {
  type        = string
  description = "Tên tài khoản quản trị PostgreSQL"
}

variable "db_password" {
  type        = string
  description = "Mật khẩu Database PostgreSQL"
  sensitive   = true
}

variable "db_instance_class" {
  type        = string
  description = "Loại cấu hình máy chủ RDS (Floci/Dev: db.t3.micro, Prod: db.t3.medium)"
}

variable "db_allocated_storage" {
  type        = number
  description = "Dung lượng ổ đĩa lưu trữ RDS (GB)"
}

variable "multi_az" {
  type        = bool
  description = "Công tắc bật Multi-AZ High Availability (Floci: false, Prod: true)"
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Bỏ qua chụp snapshot khi xóa DB (Floci/Dev: true, Prod: false)"
}

variable "enable_elasticache" {
  type        = bool
  description = "Công tắc bật/tắt ElastiCache Redis"
}

variable "redis_node_type" {
  type        = string
  description = "Loại node ElastiCache Redis (ví dụ: cache.t3.micro)"
}
