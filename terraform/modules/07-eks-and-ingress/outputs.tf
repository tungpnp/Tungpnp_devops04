# File: terraform/modules/07-eks-and-ingress/outputs.tf
# Mục đích: Xuất thông tin cụm Amazon EKS và DNS Name của Application Load Balancer

output "eks_cluster_name" {
  description = "Tên cụm Amazon EKS"
  value       = var.enable_eks ? aws_eks_cluster.main[0].name : null
}

output "eks_cluster_endpoint" {
  description = "API Server Endpoint của cụm EKS"
  value       = var.enable_eks ? aws_eks_cluster.main[0].endpoint : null
}

output "alb_arn" {
  description = "ARN của Application Load Balancer"
  value       = var.enable_alb ? aws_lb.main[0].arn : null
}

output "alb_dns_name" {
  description = "DNS Name công khai của Application Load Balancer"
  value       = var.enable_alb ? aws_lb.main[0].dns_name : null
}
