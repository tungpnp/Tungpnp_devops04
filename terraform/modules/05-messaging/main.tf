# File: terraform/modules/05-messaging/main.tf
# Mục đích: Xây dựng kiến trúc truyền tin bất đồng bộ chuẩn Event-Driven (SNS Pub/Sub -> SQS Queue + Dead Letter Queue)
# Chuẩn áp dụng: AWS Messaging Best Practices (Không mất sự kiện khi Worker quá tải/lỗi)

# 1. Tạo Dead Letter Queue (DLQ) chuyên hứng tin nhắn lỗi để phân tích và phục hồi
resource "aws_sqs_queue" "order_dlq" {
  name                      = "${var.project_name}-${var.environment}-order-dlq"
  message_retention_seconds = 1209600 # Giữ lại 14 ngày để kỹ sư điều tra sự cố

  tags = {
    Name = "${var.project_name}-${var.environment}-order-dlq"
    Role = "DeadLetterQueue"
  }
}

# 2. Tạo Hàng đợi Chính xử lý sự kiện giao dịch / hoạt động người dùng (gắn Redrive Policy trỏ sang DLQ)
resource "aws_sqs_queue" "order_queue" {
  name                       = "${var.project_name}-${var.environment}-order-queue"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600 # 4 ngày

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-order-queue"
    Role = "PrimaryQueue"
  }
}

# 3. Tạo Đài phát thanh Sự kiện Amazon SNS Topic (Mô hình Fan-out phát sóng sự kiện)
resource "aws_sns_topic" "trading_events" {
  name = "${var.project_name}-${var.environment}-trading-events"

  tags = {
    Name = "${var.project_name}-${var.environment}-trading-events"
  }
}

# 4. Đăng ký (Subscribe) hàng đợi SQS lắng nghe sự kiện phát từ SNS Topic
resource "aws_sns_topic_subscription" "order_queue_sub" {
  topic_arn = aws_sns_topic.trading_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.order_queue.arn
}

# 5. Cấp quyền SQS Queue Policy cho phép SNS Topic gửi tin nhắn vào SQS
resource "aws_sqs_queue_policy" "allow_sns" {
  queue_url = aws_sqs_queue.order_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSNSTopicPublishToSQS"
        Effect    = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.order_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.trading_events.arn
          }
        }
      }
    ]
  })
}
