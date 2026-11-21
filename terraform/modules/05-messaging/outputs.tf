# File: terraform/modules/05-messaging/outputs.tf
# Mục đích: Xuất ARN của SNS Topic và URL/ARN của SQS Queue + DLQ cho Microservices

output "sns_topic_arn" {
  description = "ARN của SNS Topic phát sóng sự kiện Trading"
  value       = aws_sns_topic.trading_events.arn
}

output "order_queue_url" {
  description = "URL của hàng đợi SQS chính (order-queue)"
  value       = aws_sqs_queue.order_queue.url
}

output "order_queue_arn" {
  description = "ARN của hàng đợi SQS chính (order-queue)"
  value       = aws_sqs_queue.order_queue.arn
}

output "order_dlq_url" {
  description = "URL của hàng đợi hứng lỗi Dead Letter Queue (order-dlq)"
  value       = aws_sqs_queue.order_dlq.url
}
