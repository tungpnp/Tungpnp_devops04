# File: terraform/modules/02-security/main.tf
# Mục đích: Thiết lập Hệ thống Khiên chắn 3 lớp (Security Group Chaining: ALB -> App -> DB) và IAM Role chuẩn Least-Privilege
# Chuẩn áp dụng: AWS Well-Architected Framework (Security Pillar) - Không mở cổng Database/Backend ra Internet

# ==============================================================================
# PHẦN 1: HỆ THỐNG TƯỜNG LỬA MÓC XÍCH 3 LỚP (3-TIER SECURITY GROUP CHAINING)
# ==============================================================================

# 1. Lớp Khiên 1: ALB Security Group (Đặt tại Public Subnet - Đón khách từ Internet)
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Tang 1 (Public): Cho phep HTTP (80) va HTTPS (443) tu Internet vao Application Load Balancer"
  vpc_id      = var.vpc_id

  # Cho phép khách hàng từ Internet gọi vào cổng 80 (HTTP)
  ingress {
    description = "Allow HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Cho phép khách hàng từ Internet gọi vào cổng 443 (HTTPS)
  ingress {
    description = "Allow HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Cho phép ALB chuyển tiếp lưu lượng đi ra các tầng bên trong
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
    Tier = "Public-LoadBalancer"
  }
}

# 2. Lớp Khiên 2: Application / K8s Security Group (Đặt tại Private Subnet - Bảo vệ Frontend, API Gateway, Backend Java)
resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Tang 2 (Private App/K8s): Chi nhan traffic tu ALB (80, 3001) va giao tiep noi bo K8s (8080)"
  vpc_id      = var.vpc_id

  # Luồng 1: Chỉ cho phép ALB (đeo thẻ alb-sg) gọi vào cổng 80 của Pod frontend-react (Nginx)
  ingress {
    description     = "Allow HTTP (80) to Frontend React ONLY from ALB Security Group"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Luồng 2: Chỉ cho phép ALB (đeo thẻ alb-sg) gọi vào cổng 3001 của Pod api-gateway (Node.js)
  ingress {
    description     = "Allow API traffic (3001) to API Gateway ONLY from ALB Security Group"
    from_port       = 3001
    to_port         = 3001
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Luồng 3: Cổng 8080 của Pod backend-java (Spring Boot) TUYỆT ĐỐI KHÔNG cho ALB gọi thẳng,
  # mà chỉ cho phép các Pod đeo cùng thẻ app-sg (như api-gateway) gọi sang nhau (self = true)!
  ingress {
    description = "Allow internal K8s communication (e.g. API Gateway calling Backend Java on 8080)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    self        = true
  }

  # Cho phép các Pod ứng dụng gọi ra ngoài (tới Database, Redis, Secrets Manager, S3, SQS)
  egress {
    description = "Allow outbound traffic from App Pods"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-sg"
    Tier = "Private-Application"
  }
}

# 3. Lớp Khiên 3: Database & Cache Security Group (Đặt tại Private Subnet - Bảo vệ RDS PostgreSQL & ElastiCache Redis)
resource "aws_security_group" "db" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Tang 3 (Private Data): Co lap tuyet doi, CHI nhan ket noi 5432/6379 tu App Security Group"
  vpc_id      = var.vpc_id

  # Chỉ mở cổng 5432 (PostgreSQL) cho những máy chủ/Pod đeo chiếc thẻ app-sg (Backend Java)
  ingress {
    description     = "Allow PostgreSQL (5432) ONLY from App Security Group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # Chỉ mở cổng 6379 (Redis) cho những máy chủ/Pod đeo chiếc thẻ app-sg (API Gateway / Backend)
  ingress {
    description     = "Allow Redis (6379) ONLY from App Security Group"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Allow outbound replies"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-db-sg"
    Tier = "Private-Database"
  }
}

# ==============================================================================
# PHẦN 2: QUẢN TRỊ ĐỊNH DANH & PHÂN QUYỀN TỐI THIỂU (IAM LEAST-PRIVILEGE)
# Cấp "Thẻ nhân viên tạm thời" (IAM Role) để Backend Java tự đọc mật khẩu từ Két sắt
# ==============================================================================

# 4. Khởi tạo IAM Role dành cho tầng Ứng dụng (EC2 Worker Nodes / EKS Pods)
resource "aws_iam_role" "app" {
  name        = "${var.project_name}-${var.environment}-app-role"
  description = "IAM Role cap quyen cho ung dung K8s doc mat khau tu Secrets Manager va SSM"

  # Chính sách tin cậy (Trust Policy): Cho phép EC2 Worker Nodes, EKS Control Plane và EKS Pod Identity (pods.eks.amazonaws.com) mượn chiếc thẻ Role này qua STS
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2AndEKSPodsToAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com",
            "eks.amazonaws.com",
            "pods.eks.amazonaws.com"
          ]
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-app-role"
  }
}

# 5. Khởi tạo IAM Policy chuẩn Least-Privilege (Quyền tối thiểu):
# Khắc phục triệt để lỗi bảo mật '*:*': Chỉ cấp quyền ĐỌC (Get/Describe) và khóa chặt vào nhánh '/trading/*'
resource "aws_iam_policy" "app_secrets_read" {
  name        = "${var.project_name}-${var.environment}-secrets-read-policy"
  description = "Chinh sach Least-Privilege: Chi cho phep DOC bi mat trong nhanh /trading/*"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadTradingSecretsOnly"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:/trading/*"
      },
      {
        Sid    = "AllowReadTradingSSMParametersOnly"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/trading/*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-secrets-read-policy"
  }
}

# 6. Đính kèm (Attach) văn bản Policy vừa tạo vào chiếc thẻ IAM Role của ứng dụng
resource "aws_iam_role_policy_attachment" "app_secrets" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.app_secrets_read.arn
}

