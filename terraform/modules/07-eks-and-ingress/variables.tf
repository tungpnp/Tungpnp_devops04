# File: terraform/modules/07-eks-and-ingress/variables.tf
# Mục đích: Định nghĩa tham số đầu vào cho Module 07-eks-and-ingress (Amazon EKS Cluster & Application Load Balancer)

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

variable "cluster_name" {
  type        = string
  description = "Tên cụm Amazon EKS"
}

variable "kubernetes_version" {
  type        = string
  description = "Phiên bản Kubernetes của cụm EKS (ví dụ: 1.30)"
}

variable "vpc_id" {
  type        = string
  description = "ID của mạng VPC từ Module 01-vpc"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Danh sách Public Subnet IDs để đặt Application Load Balancer"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Danh sách Private Subnet IDs cho EKS Worker Nodes"
}

variable "alb_sg_id" {
  type        = string
  description = "ID của Khiên 1 (ALB Security Group) từ Module 02-security"
}

variable "app_sg_id" {
  type        = string
  description = "ID của Khiên 2 (App/EKS Security Group) từ Module 02-security"
}

variable "enable_eks" {
  type        = bool
  description = "Công tắc bật/tắt khởi tạo Amazon EKS Cluster"
}

variable "enable_alb" {
  type        = bool
  description = "Công tắc bật/tắt khởi tạo Application Load Balancer Layer 7"
}
