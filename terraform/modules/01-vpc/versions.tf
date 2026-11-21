# File: terraform/modules/01-vpc/versions.tf
# Mục đích: Khai báo phiên bản tối thiểu của Terraform và AWS Provider mà module 01-vpc yêu cầu
# Chuẩn áp dụng: HashiCorp Standard Module Structure (Module con chỉ giới hạn mức tối thiểu >=, tầng environments sẽ khóa nhánh ~>)

terraform {
  # Yêu cầu Terraform từ bản 1.5.0 trở lên (khuyến nghị >= 1.11.0 khi dùng S3 native lockfile trên AWS thật)
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Module dùng chung cho phép AWS Provider từ bản 5.0 trở lên để tương thích rộng
      version = ">= 5.0"
    }
  }
}

