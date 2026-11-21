# File: terraform/environments/prod/main.tf
# Mục đích: Tái sử dụng 100% cả 7 Khuôn đúc Modules bất biến cho môi trường AWS Production

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

module "security" {
  source = "../../modules/02-security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

module "secrets" {
  source = "../../modules/03-secrets"

  project_name            = var.project_name
  environment             = var.environment
  db_username             = var.db_username
  db_password             = var.db_password
  jwt_secret              = var.jwt_secret
  recovery_window_in_days = var.recovery_window_in_days
}

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

module "messaging" {
  source = "../../modules/05-messaging"

  project_name      = var.project_name
  environment       = var.environment
  max_receive_count = var.max_receive_count
}

module "storage" {
  source = "../../modules/06-storage"

  project_name         = var.project_name
  environment          = var.environment
  ecr_repositories     = var.ecr_repositories
  force_destroy_bucket = var.force_destroy_bucket
}

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
