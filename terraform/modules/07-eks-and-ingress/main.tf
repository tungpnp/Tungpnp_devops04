# File: terraform/modules/07-eks-and-ingress/main.tf
# Mục đích: Khởi tạo cụm điều phối Kubernetes (Amazon EKS) và Cửa ngõ cân bằng tải Layer 7 (Application Load Balancer)
# Thay thế trực tiếp cho K3s VMware và Traefik Ingress ở tầng On-Premise

# 1. IAM Role cấp quyền cho AWS EKS Control Plane quản lý mạng & compute
resource "aws_iam_role" "eks_cluster" {
  count = var.enable_eks ? 1 : 0
  name  = "${var.project_name}-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowEKSServiceAssumeRole"
        Effect    = "Allow"
        Principal = { Service = "eks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-eks-cluster-role"
  }
}

# 2. Gắn Policy chuẩn của AWS cho EKS Cluster Role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count      = var.enable_eks ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster[0].name
}

# 3. Khởi tạo cụm Amazon EKS Cluster
resource "aws_eks_cluster" "main" {
  count    = var.enable_eks ? 1 : 0
  name     = "${var.cluster_name}-${var.environment}"
  version  = var.kubernetes_version
  role_arn = aws_iam_role.eks_cluster[0].arn

  vpc_config {
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    security_group_ids      = [var.app_sg_id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]

  tags = {
    Name = "${var.cluster_name}-${var.environment}"
  }
}

# 4. Khởi tạo Cửa ngõ Application Load Balancer (Layer 7) đặt tại Public Subnets
resource "aws_lb" "main" {
  count              = var.enable_alb ? 1 : 0
  name               = "trading-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
    Tier = "Public-LoadBalancer"
  }
}

# 5. Nhóm đích (Target Group) cho Frontend React (Cổng 80)
resource "aws_lb_target_group" "frontend" {
  count       = var.enable_alb ? 1 : 0
  name        = "trading-${var.environment}-fe-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-fe-tg"
  }
}

# 6. Nhóm đích (Target Group) cho API Gateway Node.js (Cổng 3001)
resource "aws_lb_target_group" "api_gateway" {
  count       = var.enable_alb ? 1 : 0
  name        = "trading-${var.environment}-gw-tg"
  port        = 3001
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-gw-tg"
  }
}

# 7. Cổng lắng nghe HTTP (Port 80) của ALB: mặc định đẩy vào Frontend React
resource "aws_lb_listener" "http" {
  count             = var.enable_alb ? 1 : 0
  load_balancer_arn = aws_lb.main[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend[0].arn
  }
}

# 8. Luật định tuyến Layer 7: Mọi request có tiền tố /api/* được chuyển thẳng vào API Gateway (Port 3001)
resource "aws_lb_listener_rule" "api_routing" {
  count        = var.enable_alb ? 1 : 0
  listener_arn = aws_lb_listener.http[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_gateway[0].arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}
