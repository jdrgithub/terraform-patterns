module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr    = var.vpc_cidr
  name_prefix = var.name_prefix
  subnets     = var.subnets
}