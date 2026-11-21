# File: terraform/modules/02-security/variables.tf
# Mục đích: Định nghĩa các tham số đầu vào (Inputs) cho module Tường lửa 3 lớp (Security Groups) & Phân quyền IAM
# Lưu ý: Module dùng chung bất biến, tuyệt đối không gắn cứng thông số của môi trường cụ thể.

# 1. Tên dự án
variable "project_name" {
  type        = string
  description = "Tên định danh dự án (ví dụ: tungpnp-trading)"
}

# 2. Tên môi trường triển khai
variable "environment" {
  type        = string
  description = "Tên môi trường triển khai (floci, local, dev, staging, prod, dr)"

  validation {
    condition     = contains(["floci", "local", "dev", "staging", "prod", "dr"], var.environment)
    error_message = "Giá trị environment phải nằm trong danh sách chuẩn: floci, local, dev, staging, prod, dr."
  }
}

# 3. ID của mạng VPC (Được truyền tự động từ đầu ra module.vpc.vpc_id của module 01-vpc)
variable "vpc_id" {
  type        = string
  description = "ID của mạng VPC nơi sẽ đặt 3 lớp tường lửa Security Groups"

  validation {
    condition     = length(var.vpc_id) > 4 && substr(var.vpc_id, 0, 4) == "vpc-"
    error_message = "vpc_id phải là mã VPC hợp lệ bắt đầu bằng tiền tố 'vpc-'."
  }
}

