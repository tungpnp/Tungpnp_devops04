# File: terraform/modules/04-database/versions.tf
# Mục đích: Khai báo phiên bản tối thiểu của Terraform và AWS Provider cho Module 04-database
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
