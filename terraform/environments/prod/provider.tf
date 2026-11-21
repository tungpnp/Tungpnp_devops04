# File: terraform/environments/prod/provider.tf
# Mục đích: Định cấu hình Terraform chuẩn Enterprise triển khai lên AWS Thật (Production - Region Singapore)
# Điểm khác biệt duy nhất so với Floci: Kết nối trực tiếp AWS Cloud & kích hoạt S3 Remote Backend (use_lockfile = true)

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Lưu trữ Terraform State tập trung và khóa trạng thái tự động trên Amazon S3 (Chuẩn Terraform 1.11+)
  # Khi triển khai thực tế lên AWS Production, tạo trước S3 Bucket bật Versioning rồi mở comment khối dưới đây:
  # backend "s3" {
  #   bucket       = "tungpnp-trading-terraform-state-prod"
  #   key          = "trading-platform/prod/terraform.tfstate"
  #   region       = "ap-southeast-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "tungpnp"
    }
  }
}
