# File: terraform/modules/06-storage/main.tf
# Mục đích: Khởi tạo Amazon S3 Bucket (lưu báo cáo/backup) chuẩn bảo mật và các kho Amazon ECR chứa Docker Images
# Chuẩn áp dụng: CIS AWS Foundations Benchmark (Block Public Access, Encryption, Versioning, Scan-on-Push)

# 1. Khởi tạo S3 Bucket lưu báo cáo giao dịch và bản sao lưu hệ thống
resource "aws_s3_bucket" "reports" {
  bucket        = "${var.project_name}-${var.environment}-reports"
  force_destroy = var.force_destroy_bucket

  tags = {
    Name = "${var.project_name}-${var.environment}-reports"
  }
}

# 2. Bật lưu lịch sử phiên bản (Versioning) để phục hồi nếu ghi đè nhầm file
resource "aws_s3_bucket_versioning" "reports" {
  bucket = aws_s3_bucket.reports.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Kích hoạt mã hóa dữ liệu mặc định (Server-Side Encryption AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "reports" {
  bucket = aws_s3_bucket.reports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. Khóa chặn 100% truy cập công khai vào S3 Bucket (Security Pillar)
resource "aws_s3_bucket_public_access_block" "reports" {
  bucket = aws_s3_bucket.reports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 5. Khởi tạo danh sách kho chứa Docker Image riêng tư Amazon ECR bằng vòng lặp for_each
resource "aws_ecr_repository" "services" {
  for_each             = toset(var.ecr_repositories)
  name                 = "${var.project_name}-${var.environment}/${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = var.force_destroy_bucket

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-${each.key}-ecr"
    Service = each.key
  }
}

# 6. Quy hoạch vòng đời tự động dọn Image cũ (chỉ giữ 10 phiên bản gần nhất để tiết kiệm lưu trữ)
resource "aws_ecr_lifecycle_policy" "services" {
  for_each   = aws_ecr_repository.services
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Giu lai 10 image moi nhat cho moi microservice"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
