module "vpc_a" {
  source = "../../modules/vpc-nrwl"

  vpc_cidr        = var.vpc_cidr_a
  name_postfix    = var.name_postfix_a
  public_subnets  = var.public_subnets_one
  private_subnets = var.private_subnets_one
}

module "vpc_b" {
  count  = var.enable_peering ? 1 : 0
  source = "../../modules/vpc-nrwl"

  vpc_cidr        = var.vpc_cidr_b
  name_postfix    = var.name_postfix_b
  public_subnets  = var.public_subnets_two
  private_subnets = var.private_subnets_two
}


# Requester's side of the connection.
resource "aws_vpc_peering_connection" "peer" {
  count = var.enable_peering ? 1 : 0

  vpc_id = module.vpc_a.vpc_id
  # 0 needed below because count in module.vpc_b 
  # creates list of module instances
  peer_vpc_id = module.vpc_b[0].vpc_id
  # same acct and region enables auto acceptance 
  auto_accept = true

}