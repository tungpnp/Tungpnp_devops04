# File: terraform/modules/03-secrets/main.tf
# Mục đích: Khởi tạo Két sắt Secrets Manager (chứa thông tin đăng nhập DB) và SSM Parameter Store (chứa JWT Secret)
# Chuẩn áp dụng: 12-Factor App (Factor III - Config) & AWS Security Pillar (Không lưu mật khẩu trong code/YAML)

# 1. Khởi tạo vỏ Két sắt AWS Secrets Manager cho Database PostgreSQL
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "/trading/${var.environment}/database/credentials"
  description             = "Thong tin dang nhap RDS PostgreSQL cua moi truong ${var.environment}"
  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name = "${var.project_name}-${var.environment}-db-credentials"
  }
}

# 2. Nạp giá trị JSON (Username & Password) vào Két sắt Secrets Manager
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}

# 3. Lưu riêng mật khẩu DB vào AWS SSM Parameter Store (kiểu SecureString mã hóa KMS)
resource "aws_ssm_parameter" "db_password" {
  name        = "/trading/${var.environment}/db/password"
  description = "Mat khau PostgreSQL ma hoa SecureString cho ${var.environment}"
  type        = "SecureString"
  value       = var.db_password
  overwrite   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-ssm-db-password"
  }
}

# 4. Lưu khóa ký JWT Token vào AWS SSM Parameter Store (kiểu SecureString mã hóa KMS)
resource "aws_ssm_parameter" "jwt_secret" {
  name        = "/trading/${var.environment}/jwt/secret"
  description = "Khoa ky JWT HMAC-SHA256 ma hoa SecureString cho Backend Java"
  type        = "SecureString"
  value       = var.jwt_secret
  overwrite   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-ssm-jwt-secret"
  }
}
