# File: terraform/environments/floci/provider.tf
# Mục đích: Định cấu hình Terraform AWS Provider kết nối an toàn vào cụm giả lập Floci cục bộ (0đ)
# Chuẩn áp dụng: Không hardcode credentials trong code (dùng AWS Profile) & tự động gắn nhãn bằng default_tags

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # Đọc thông tin xác thực từ ~/.aws/credentials (Profile 'floci')
  region  = var.aws_region
  profile = var.aws_profile

  # Bỏ qua kiểm tra xác thực AWS thật để chạy tức thì trên Floci
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Bắt buộc bật Path-Style cho S3 trên trình giả lập local
  s3_use_path_style = true

  # Khóa chặt toàn bộ dịch vụ AWS cốt lõi về endpoint Floci cục bộ (đảm bảo không bắn nhầm lên AWS thật)
  endpoints {
    iam            = var.floci_endpoint
    sts            = var.floci_endpoint
    kms            = var.floci_endpoint
    secretsmanager = var.floci_endpoint
    ssm            = var.floci_endpoint
    ec2            = var.floci_endpoint
    ecr            = var.floci_endpoint
    ecs            = var.floci_endpoint
    eks            = var.floci_endpoint
    elb            = var.floci_endpoint
    elbv2          = var.floci_endpoint
    lambda         = var.floci_endpoint
    s3             = var.floci_endpoint
    rds            = var.floci_endpoint
    elasticache    = var.floci_endpoint
    dynamodb       = var.floci_endpoint
    sqs            = var.floci_endpoint
    sns            = var.floci_endpoint
    logs           = var.floci_endpoint
    cloudwatch     = var.floci_endpoint
    route53        = var.floci_endpoint
  }

  # Tự động gắn nhãn chuẩn doanh nghiệp cho mọi tài nguyên sinh ra
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "tungpnp"
    }
  }
}
