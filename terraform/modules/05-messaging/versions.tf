# File: terraform/modules/05-messaging/versions.tf
# Mục đích: Khai báo phiên bản tối thiểu của Terraform và AWS Provider cho Module 05-messaging

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
