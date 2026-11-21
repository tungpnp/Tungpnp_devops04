# File: terraform/modules/04-database/outputs.tf
# Mục đích: Xuất Endpoint kết nối của RDS PostgreSQL và ElastiCache Redis

output "rds_identifier" {
  description = "Tên định danh của RDS PostgreSQL Instance"
  value       = aws_db_instance.postgres.identifier
}

output "rds_endpoint" {
  description = "Địa chỉ Endpoint đầy đủ (Host:Port) của RDS PostgreSQL"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "Tên miền Hostname của RDS PostgreSQL"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "Cổng kết nối RDS PostgreSQL (5432)"
  value       = aws_db_instance.postgres.port
}

output "redis_endpoint" {
  description = "Địa chỉ Endpoint của node ElastiCache Redis đầu tiên"
  value       = var.enable_elasticache ? aws_elasticache_cluster.redis[0].cache_nodes[0].address : null
}
