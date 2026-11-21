# File: terraform/modules/03-secrets/versions.tf
# Mục đích: Khai báo phiên bản tối thiểu của Terraform và AWS Provider cho Module 03-secrets
# Chuẩn áp dụng: HashiCorp Standard Module Structure

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
