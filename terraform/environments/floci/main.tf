# File: terraform/environments/floci/main.tf
# Mục đích: Nhạc trưởng lắp ráp trọn bộ 7 Modules hạ tầng AWS lên môi trường giả lập Floci (0đ)
# Chuẩn áp dụng: Dependency Chain rõ ràng (01-vpc -> 02-security -> 03-secrets -> 04-database -> 05-messaging -> 06-storage -> 07-eks-and-ingress)

# 1. Module Mạng VPC, Subnets, IGW & Route Tables
module "vpc" {
  source = "../../modules/01-vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  enable_eks_tags    = var.enable_eks_tags
  cluster_name       = var.cluster_name
}

# 2. Module Tường lửa 3 lớp (ALB -> App -> DB) & IAM Role Least-Privilege
module "security" {
  source = "../../modules/02-security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

# 3. Module Két sắt Bí mật (Secrets Manager cho DB & SSM SecureString cho JWT)
module "secrets" {
  source = "../../modules/03-secrets"

  project_name            = var.project_name
  environment             = var.environment
  db_username             = var.db_username
  db_password             = var.db_password
  jwt_secret              = var.jwt_secret
  recovery_window_in_days = var.recovery_window_in_days
}

# 4. Module Cơ sở dữ liệu (RDS PostgreSQL & ElastiCache Redis đặt trong Private Subnet)
module "database" {
  source = "../../modules/04-database"

  project_name         = var.project_name
  environment          = var.environment
  private_subnet_ids   = module.vpc.private_subnet_ids
  db_sg_id             = module.security.db_sg_id
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  multi_az             = var.multi_az
  skip_final_snapshot  = var.skip_final_snapshot
  enable_elasticache   = var.enable_elasticache
  redis_node_type      = var.redis_node_type

  depends_on = [module.secrets]
}

# 5. Module Truyền tin Bất đồng bộ (SNS Topic -> SQS Order Queue + Dead Letter Queue)
module "messaging" {
  source = "../../modules/05-messaging"

  project_name      = var.project_name
  environment       = var.environment
  max_receive_count = var.max_receive_count
}

# 6. Module Lưu trữ (S3 Bucket bảo mật & 4 Kho chứa Docker Image Amazon ECR)
module "storage" {
  source = "../../modules/06-storage"

  project_name         = var.project_name
  environment          = var.environment
  ecr_repositories     = var.ecr_repositories
  force_destroy_bucket = var.force_destroy_bucket
}

# 7. Module Cụm điều phối Kubernetes (Amazon EKS) & Cửa ngõ Application Load Balancer
module "eks_and_ingress" {
  source = "../../modules/07-eks-and-ingress"

  project_name       = var.project_name
  environment        = var.environment
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  alb_sg_id          = module.security.alb_sg_id
  app_sg_id          = module.security.app_sg_id
  enable_eks         = var.enable_eks
  enable_alb         = var.enable_alb
}
