module "vpc" {
  source = "../modules/vpc"

  vpc_cidr    = var.vpc_cidr
  name_prefix = var.name_prefix
}

module "ec2" {
  source = "../modules/ec2"

  sg_cidr   = var.sg_cidr
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids["us-east-1a"]
}

