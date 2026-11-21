# File: terraform/modules/06-storage/variables.tf
# Mục đích: Định nghĩa tham số đầu vào cho Module 06-storage (Amazon S3 Bucket & Amazon ECR Repositories)

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

variable "ecr_repositories" {
  type        = list(string)
  description = "Danh sách tên các Microservices cần tạo kho Docker Image trên Amazon ECR"

  validation {
    condition     = length(var.ecr_repositories) >= 1
    error_message = "Phải có ít nhất 1 service cần tạo ECR Repository."
  }
}

variable "force_destroy_bucket" {
  type        = bool
  description = "Cho phép terraform destroy xóa luôn bucket chứa dữ liệu (Floci/Dev: true, Prod: false để chống mất dữ liệu)"
}
