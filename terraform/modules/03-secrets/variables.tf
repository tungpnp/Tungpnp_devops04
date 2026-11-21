# File: terraform/modules/03-secrets/variables.tf
# Mục đích: Định nghĩa tham số đầu vào cho Module 03-secrets (Secrets Manager & SSM Parameter Store)
# Lưu ý bảo mật: Mọi biến chứa mật khẩu/chuỗi bí mật đều gắn cờ sensitive = true

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

variable "db_username" {
  type        = string
  description = "Tên đăng nhập quản trị PostgreSQL lưu kèm trong Secrets Manager"
}

variable "db_password" {
  type        = string
  description = "Mật khẩu Database PostgreSQL (được truyền từ TF_VAR hoặc file tfvars bảo mật)"
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Mật khẩu Database phải có ít nhất 8 ký tự theo tiêu chuẩn bảo mật."
  }
}

variable "jwt_secret" {
  type        = string
  description = "Chuỗi bí mật ký JWT Token của Backend Java"
  sensitive   = true

  validation {
    condition     = length(var.jwt_secret) >= 32
    error_message = "JWT Secret phải dài tối thiểu 32 ký tự để đảm bảo an toàn cho thuật toán HMAC-SHA256."
  }
}

variable "recovery_window_in_days" {
  type        = number
  description = "Số ngày giữ bí mật trong thùng rác trước khi xóa vĩnh viễn (Floci/Dev dùng 0 để xóa sạch ngay, Prod dùng 7-30)"

  validation {
    condition     = var.recovery_window_in_days >= 0 && var.recovery_window_in_days <= 30
    error_message = "recovery_window_in_days phải nằm trong khoảng từ 0 đến 30 ngày."
  }
}
