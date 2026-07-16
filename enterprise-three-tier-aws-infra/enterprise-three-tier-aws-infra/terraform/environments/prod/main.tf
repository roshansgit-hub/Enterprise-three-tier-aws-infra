terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {
    bucket         = "REPLACE-ME-terraform-state-bucket"
    key            = "prod/three-tier-infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = "three-tier-aws-infra"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  environment               = var.environment
  vpc_cidr                  = var.vpc_cidr
  azs                       = var.azs
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_app_subnet_cidrs  = var.private_app_subnet_cidrs
  private_db_subnet_cidrs   = var.private_db_subnet_cidrs
  single_nat_gateway        = false # HA NAT per-AZ for prod
  tags                      = local.common_tags
}

module "security" {
  source = "../../modules/security"

  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  app_port    = var.app_port
  tags        = local.common_tags
}

module "alb" {
  source = "../../modules/alb"

  environment                = var.environment
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  alb_sg_id                  = module.security.alb_sg_id
  app_port                   = var.app_port
  acm_certificate_arn        = var.acm_certificate_arn
  enable_deletion_protection = true
  tags                       = local.common_tags
}

module "ec2_asg" {
  source = "../../modules/ec2-asg"

  environment             = var.environment
  aws_region              = var.aws_region
  app_sg_id               = module.security.app_sg_id
  private_app_subnet_ids  = module.vpc.private_app_subnet_ids
  target_group_arn        = module.alb.target_group_arn
  ecr_image_uri           = var.ecr_image_uri
  app_port                = var.app_port
  desired_capacity        = 3
  min_size                = 2
  max_size                = 8
  tags                    = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  environment            = var.environment
  private_db_subnet_ids  = module.vpc.private_db_subnet_ids
  db_sg_id               = module.security.db_sg_id
  multi_az               = true
  deletion_protection    = true
  skip_final_snapshot    = false
  tags                   = local.common_tags
}
