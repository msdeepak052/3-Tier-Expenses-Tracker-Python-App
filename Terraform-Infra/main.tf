module "vpc" {
  source = "./modules/vpc"

  vpc_cidr                   = var.vpc_cidr
  vpc_name                   = var.vpc_name
  subnets                    = var.subnets
  pvt_destination_route_cidr = var.pvt_destination_route_cidr
  availability_zones         = var.availability_zones
}

module "sg" {

  source          = "./modules/sg"
  vpc_id          = module.vpc.vpc_id
  security_groups = var.security_groups
  
  depends_on = [module.vpc, module.eks]
}
module "rds" {
  source                 = "./modules/rds"
  subnet_ids             = module.vpc.private_subnet_ids
  identifier             = var.rds_identifier
  instance_class         = var.rds_instance_class
  allocated_storage      = var.rds_allocated_storage
  max_allocated_storage  = var.rds_max_allocated_storage
  engine                 = var.rds_engine
  engine_version         = var.rds_engine_version
  db_username            = var.rds_username
  db_name                = var.rds_name
  parameter_group_family = var.rds_parameter_group_family
  vpc_security_group_ids = module.sg.security_group_ids["rds"]
  skip_final_snapshot    = var.rds_skip_final_snapshot
  publicly_accessible    = var.rds_publicly_accessible
  multi_az               = var.rds_multi_az
  storage_encrypted      = var.rds_storage_encrypted
  apply_immediately      = var.rds_apply_immediately

  environment = var.environment
  application = var.application

  depends_on = [module.vpc, ]
}


# This Terraform configuration sets up an AWS infrastructure with a VPC, EKS cluster, ECR repository, and EC2 instances.

module "eks" {
  source = "./modules/eks"

  cluster_name  = var.cluster_name
  k8s_version   = var.k8s_version
  subnet_ids    = module.vpc.public_subnet_ids
  desired_nodes = var.desired_nodes
  max_nodes     = var.max_nodes
  min_nodes     = var.min_nodes
  instance_type = var.eks_instance_type
  providers = {
    kubectl = kubectl
  }
}

module "ecr" {
  source = "./modules/ecr"

  name_ecr              = var.name_ecr
  enable_immutable_tags = var.enable_immutable_tags
  ecr_tags              = var.ecr_tags

}


module "ec2" {
  source = "./modules/ec2"

  ami_id                               = var.ami_id
  instance_type                        = var.ec2_instance_type
  subnet_ids                           = module.vpc.public_subnet_ids
  key_name                             = var.key_name
  vpc_id                               = module.vpc.vpc_id
  security_group_id_self-hosted-runner = module.sg.security_group_ids["self-hosted-runner"]
  security_group_id_nexus              = module.sg.security_group_ids["nexus"]
  security_group_id_sonarqube          = module.sg.security_group_ids["sonarqube"]


  cluster_name = var.cluster_name
  aws_region   = var.aws_region

  depends_on = [module.eks, module.ecr, module.sg]
}