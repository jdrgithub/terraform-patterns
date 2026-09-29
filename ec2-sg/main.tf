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

module "secret" {
  source      = "../module/secrets"
  
  name        = "dev/demo-app/api-key"
  description = "API key used by the demo application"

  tags = {
    Environment = "dev"
  }

}

module "iam" {
  source = "../modules/iam"

  bucket_arn = ""
  secret_arn = module.secret.secret_arn

}

module "secret" {
  source      = "../modules/secrets"
  name        = "dev/demo-app/api-key"
  description = "API key for app"

  tags = {
    Environment = "dev"
  }
} 