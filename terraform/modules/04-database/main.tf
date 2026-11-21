# File: terraform/modules/04-database/main.tf
# Mục đích: Khởi tạo cụm Cơ sở dữ liệu Amazon RDS PostgreSQL & Bộ nhớ đệm ElastiCache Redis trong Private Subnets
# Chuẩn áp dụng: AWS Well-Architected Reliability & Security Pillars (Không mở Public Access, mã hóa lưu trữ)

# 1. Tạo DB Subnet Group từ danh sách Private Subnets (cách ly khỏi Internet)
resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "Private DB Subnet Group cho RDS PostgreSQL (${var.environment})"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# 2. Khởi tạo Cơ sở dữ liệu quan hệ Amazon RDS for PostgreSQL
resource "aws_db_instance" "postgres" {
  identifier             = "${var.project_name}-${var.environment}-postgres"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  storage_type           = "gp3"
  storage_encrypted      = true
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]
  publicly_accessible    = false
  multi_az               = var.multi_az
  skip_final_snapshot    = var.skip_final_snapshot

  tags = {
    Name = "${var.project_name}-${var.environment}-postgres"
    Tier = "Private-Database"
  }
}

# 3. Tạo ElastiCache Subnet Group đặt trong Private Subnets
resource "aws_elasticache_subnet_group" "redis" {
  count       = var.enable_elasticache ? 1 : 0
  name        = "${var.project_name}-${var.environment}-redis-subnet-group"
  description = "Private Subnet Group cho ElastiCache Redis (${var.environment})"
  subnet_ids  = var.private_subnet_ids
}

# 4. Khởi tạo Bộ nhớ đệm In-Memory ElastiCache Redis (hỗ trợ Rate Limit & Session)
resource "aws_elasticache_cluster" "redis" {
  count                = var.enable_elasticache ? 1 : 0
  cluster_id           = "${var.project_name}-${var.environment}-redis"
  engine               = "redis"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis[0].name
  security_group_ids   = [var.db_sg_id]

  tags = {
    Name = "${var.project_name}-${var.environment}-redis"
    Tier = "Private-Cache"
  }
}
