# File: terraform/modules/02-security/versions.tf
# Mục đích: Khai báo phiên bản tối thiểu của Terraform và AWS Provider cho module bảo mật 02-security
# Chuẩn áp dụng: HashiCorp Standard Module Structure (Công thức 4 File Chuẩn: versions, variables, main, outputs)

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

