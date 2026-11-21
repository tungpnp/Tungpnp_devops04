# File: terraform/modules/06-storage/outputs.tf
# Mục đích: Xuất tên S3 Bucket và bản đồ URL các kho chứa Image Amazon ECR

output "s3_bucket_id" {
  description = "Tên của S3 Bucket lưu trữ báo cáo và backup"
  value       = aws_s3_bucket.reports.id
}

output "s3_bucket_arn" {
  description = "ARN của S3 Bucket"
  value       = aws_s3_bucket.reports.arn
}

output "ecr_repository_urls" {
  description = "Map đường dẫn Repository URL của các Microservices trên Amazon ECR"
  value       = { for name, repo in aws_ecr_repository.services : name => repo.repository_url }
}
