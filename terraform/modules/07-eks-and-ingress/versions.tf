# File: terraform/modules/07-eks-and-ingress/versions.tf
# Mục đích: Khai báo phiên bản tối thiểu của Terraform và AWS Provider cho Module 07-eks-and-ingress

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
