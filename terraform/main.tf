module "vpc" {
  source = "./modules/vpc"

  project              = var.project
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  cluster_name         = var.cluster_name
}

module "eks" {
  source = "./modules/eks"

  project            = var.project
  environment        = var.environment
  cluster_name       = var.cluster_name
  eks_version        = var.eks_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  node_instance_type = var.node_instance_type
  node_min           = var.node_min
  node_max           = var.node_max
  node_desired       = var.node_desired
}

module "rds" {
  source = "./modules/rds"

  project                = var.project
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  node_security_group_id = module.eks.node_security_group_id
  db_instance_class      = var.db_instance_class
  db_name                = var.db_name
  db_username            = var.db_username
  db_allocated_storage   = var.db_allocated_storage
  db_multi_az            = var.db_multi_az
}

module "iam" {
  source = "./modules/iam"

  project           = var.project
  environment       = var.environment
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
}
