# File: terraform/modules/05-messaging/variables.tf
# Mục đích: Định nghĩa tham số đầu vào cho Module 05-messaging (SNS Topic, SQS Queue & Dead Letter Queue)

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

variable "max_receive_count" {
  type        = number
  description = "Số lần xử lý thất bại tối đa trước khi đẩy tin nhắn sang Dead Letter Queue (DLQ)"

  validation {
    condition     = var.max_receive_count >= 1 && var.max_receive_count <= 20
    error_message = "max_receive_count phải từ 1 đến 20."
  }
}
