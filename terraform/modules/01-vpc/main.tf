# File: terraform/modules/01-vpc/main.tf
# Mục đích: Định nghĩa toàn bộ tài nguyên mạng VPC, Subnets, Internet Gateway, NAT Gateway (tùy chọn) và Route Tables
# Chuẩn áp dụng: AWS Well-Architected Framework & tương thích 100% với cả Floci (Local) lẫn Amazon EKS (Production)

# ==============================================================================
# 0. BIẾN CỤC BỘ TÍNH TOÁN LOGIC LINH ĐỘNG (LOCALS)
# Giúp module tự động biến hình theo các "công tắc" truyền từ từng môi trường
# ==============================================================================
locals {
  # Tính số lượng NAT Gateway cần tạo:
  # - Nếu enable_nat_gateway = false (như trên Floci): tạo 0 cái (0đ, siêu nhẹ).
  # - Nếu enable_nat_gateway = true và single_nat_gateway = true (AWS Dev): tạo 1 cái dùng chung.
  # - Nếu enable_nat_gateway = true và single_nat_gateway = false (AWS Prod): tạo mỗi AZ 1 cái để chống sập (Multi-AZ HA).
  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)) : 0

  # Nhãn (Tags) chuyên dụng cho Public Subnet khi chạy cụm Kubernetes (EKS) để AWS Load Balancer Controller tự động tìm thấy nơi đặt ALB Internet-facing
  eks_public_subnet_tags = var.enable_eks_tags ? {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  } : {}

  # Nhãn (Tags) chuyên dụng cho Private Subnet khi chạy cụm Kubernetes (EKS) để đặt Internal Load Balancer và Worker Nodes
  eks_private_subnet_tags = var.enable_eks_tags ? {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  } : {}
}

# 1. Khởi tạo mạng riêng ảo chính (VPC)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# 2. Khóa chặt Default Security Group của VPC (Theo chuẩn bảo mật quốc tế CIS AWS Foundations Benchmark)
# Giải thích: Mặc định mỗi VPC sinh ra đều có 1 Security Group mở thông toàn bộ nội bộ; chuẩn Enterprise yêu cầu thu hồi mọi rule của nó để bắt buộc kỹ sư phải tạo Security Group tường minh ở module 02-security.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # Không khai báo khối ingress và egress nào = Cấm 100% lưu lượng qua Default SG
  tags = {
    Name = "${var.project_name}-${var.environment}-default-sg-locked"
  }
}

# 3. Khởi tạo Cổng Internet (Internet Gateway - IGW) để cho phép traffic ra/vào từ Internet ở tầng Public
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# 4. Khởi tạo các Public Subnets (Dành cho Application Load Balancer và NAT Gateway)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  # Kết hợp (merge) nhãn định danh cơ bản với nhãn tự động của EKS (nếu bật enable_eks_tags = true)
  tags = merge(
    {
      Name = "${var.project_name}-${var.environment}-public-${var.availability_zones[count.index]}"
      Tier = "Public"
    },
    local.eks_public_subnet_tags
  )
}

# 5. Khởi tạo các Private Subnets (Dành cho EKS Worker Nodes, Database RDS, Redis Cache và Backend Microservices)
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  # Kết hợp (merge) nhãn định danh cơ bản với nhãn tự động của EKS (nếu bật enable_eks_tags = true)
  tags = merge(
    {
      Name = "${var.project_name}-${var.environment}-private-${var.availability_zones[count.index]}"
      Tier = "Private"
    },
    local.eks_private_subnet_tags
  )
}

# 6. Khởi tạo IP Tĩnh (Elastic IP) và NAT Gateway (Chỉ chạy khi công tắc enable_nat_gateway = true)
resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = local.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-gw-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# 7. Bảng định tuyến Public (Public Route Table): Định tuyến lưu lượng 0.0.0.0/0 ra Internet qua IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

# 8. Gắn các Public Subnets vào Bảng định tuyến Public
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 9. Bảng định tuyến Private (Private Route Tables): Tách riêng theo từng AZ để hỗ trợ kiến trúc Multi-AZ HA trên Production
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  # Khối dynamic route: Chỉ tự động thêm đường ra NAT Gateway nếu enable_nat_gateway = true (Trên Floci khối này tự động bỏ qua)
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt-${var.availability_zones[count.index]}"
  }
}

# 10. Gắn từng Private Subnet vào Bảng định tuyến Private tương ứng của AZ đó
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
