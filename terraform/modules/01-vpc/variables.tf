# File: terraform/modules/01-vpc/variables.tf
# Mục đích: Định nghĩa các tham số đầu vào (Input Variables) và bộ lọc kiểm tra (Validation) cho module mạng VPC chuẩn quốc tế
# Lưu ý: Module là khuôn đúc dùng chung (Reusable Blueprint), không gắn cứng thông số của bất kỳ môi trường cụ thể nào.

# 1. Tên dự án (Bắt buộc môi trường gọi module phải truyền vào)
variable "project_name" {
  type        = string
  description = "Tên định danh dự án (ví dụ: tungpnp-trading), không trộn tên môi trường vào đây"
}

# 2. Môi trường triển khai (floci, dev, staging, prod, dr - Bắt buộc caller phải truyền vào)
variable "environment" {
  type        = string
  description = "Tên môi trường triển khai (floci, dev, staging, prod, dr)"

  # Kiểm tra tên môi trường phải nằm trong danh sách chuẩn hóa của doanh nghiệp
  validation {
    condition     = contains(["floci", "local", "dev", "staging", "prod", "dr"], var.environment)
    error_message = "Giá trị environment phải là một trong các môi trường chuẩn: floci, local, dev, staging, prod, dr."
  }
}

# 3. Dải CIDR của VPC (Bắt buộc caller phải truyền vào để tránh trùng lặp IP giữa các môi trường)
variable "vpc_cidr" {
  type        = string
  description = "Dải địa chỉ IP chính của mạng VPC (ví dụ: 10.0.0.0/16 cho Floci, 10.100.0.0/16 cho Prod)"

  # Kiểm tra cú pháp CIDR hợp lệ ngay từ lúc gõ lệnh terraform plan
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr phải là một dải địa chỉ IPv4 CIDR hợp lệ (ví dụ: 10.0.0.0/16)."
  }
}

# 4. Danh sách CIDR cho Public Subnets
variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Danh sách CIDR cho các Public Subnets (Nơi đặt Application Load Balancer & NAT Gateway)"

  # Đảm bảo có ít nhất 2 Public Subnets (trải trên 2 AZ) để đáp ứng yêu cầu tối thiểu của AWS ALB
  validation {
    condition     = length(var.public_subnet_cidrs) >= 2 && alltrue([for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Phải khai báo ít nhất 2 dải CIDR hợp lệ cho Public Subnets (để đủ điều kiện Multi-AZ của AWS ALB)."
  }
}

# 5. Danh sách CIDR cho Private Subnets
variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Danh sách CIDR cho các Private Subnets (Nơi đặt EKS Worker Nodes, RDS Database & ElastiCache)"

  # Đảm bảo có ít nhất 2 Private Subnets (trải trên 2 AZ) để đáp ứng yêu cầu Subnet Group của AWS RDS và EKS
  validation {
    condition     = length(var.private_subnet_cidrs) >= 2 && alltrue([for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Phải khai báo ít nhất 2 dải CIDR hợp lệ cho Private Subnets (để đủ điều kiện Multi-AZ của RDS/EKS)."
  }
}

# 6. Danh sách các Availability Zones (AZs)
variable "availability_zones" {
  type        = list(string)
  description = "Danh sách các Availability Zones (Vùng sẵn sàng) để phân bổ tài nguyên Multi-AZ"

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Cần ít nhất 2 Availability Zones (ví dụ: ap-southeast-1a, ap-southeast-1b) để đảm bảo High Availability."
  }
}

# ==============================================================================
# CÁC CÔNG TẮC LINH ĐỘNG ĐA MÔI TRƯỜNG (MULTI-ENVIRONMENT FEATURE TOGGLES)
# Giúp dùng chung 100% module này cho cả Floci (0đ) lẫn AWS Production (EKS/NAT HA)
# ==============================================================================

# 7. Công tắc bật/tắt NAT Gateway (Floci = false để tiết kiệm & nhẹ; AWS Thật = true để Private Subnet ra Internet tải gói cài đặt/Image)
variable "enable_nat_gateway" {
  type        = bool
  description = "Bật NAT Gateway cho phép Private Subnets đi ra Internet (Floci: false, AWS Dev/Prod: true)"
}

# 8. Công tắc chọn chế độ NAT Gateway tiết kiệm hay chống sập (Dev/Staging = true dùng 1 NAT; Prod = false mỗi AZ 1 NAT độc lập)
variable "single_nat_gateway" {
  type        = bool
  description = "Nếu true: chỉ tạo 1 NAT Gateway duy nhất dùng chung cho mọi AZ để tiết kiệm chi phí. Nếu false: tạo 1 NAT Gateway riêng cho mỗi AZ (Chuẩn Production HA)"
}

# 9. Công tắc tự động gắn nhãn (Tags) chuyên dụng cho cụm Kubernetes (Amazon EKS)
variable "enable_eks_tags" {
  type        = bool
  description = "Nếu true: tự động gắn tag kubernetes.io/role/elb và internal-elb vào Subnets để AWS Load Balancer Controller trên EKS tự nhận diện"
}

# 10. Tên cụm EKS (Dùng để gắn tag định danh sở hữu mạng khi enable_eks_tags = true)
variable "cluster_name" {
  type        = string
  description = "Tên cụm Kubernetes/EKS sẽ triển khai trong VPC này (ví dụ: tungpnp-trading-eks)"
}
