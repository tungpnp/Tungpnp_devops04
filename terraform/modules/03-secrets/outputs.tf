# File: terraform/modules/03-secrets/outputs.tf
# Mục đích: Xuất ARN/Name của Secrets Manager & SSM Parameters để K8s/Ứng dụng và Module Database sử dụng

output "db_secret_arn" {
  description = "ARN của Secret chứa thông tin Database trong AWS Secrets Manager"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_secret_name" {
  description = "Tên đường dẫn Secret trong AWS Secrets Manager"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "db_password_ssm_name" {
  description = "Tên đường dẫn mật khẩu DB trong AWS SSM Parameter Store"
  value       = aws_ssm_parameter.db_password.name
}

output "jwt_ssm_name" {
  description = "Tên đường dẫn JWT Secret trong AWS SSM Parameter Store"
  value       = aws_ssm_parameter.jwt_secret.name
}
