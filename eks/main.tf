provider "aws" {
  region = var.aws_region 
  # Configures the AWS provider with the region specified in variables.tf (e.g. us-east-1)
}

provider "kubernetes" {
  # This provider lets Terraform apply changes to Kubernetes resources (like namespaces, deployments)
  # To connect, it needs 3 things:
  host                   = data.aws_eks_cluster.cluster.endpoint                 # API server URL
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data) # TLS cert for API trust
  token                  = data.aws_eks_cluster_auth.cluster.token              # Auth token (short-lived)
}

# Pull in availability zone data for the selected region
data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"  # Uses a public, reusable VPC module from the Terraform Registry
  version = "5.1.0"                          # Specific version to avoid unexpected changes

  name = "eks-vpc"                           # VPC name for tagging/identification
  cidr = "10.0.0.0/16"                       # CIDR block for the entire VPC (can hold 65k+ IPs)

  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  # Automatically picks the first 2 AZs in the selected region (to create subnets across zones)

  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  # Defines two public subnets in separate AZs — one per zone — for placing EKS worker nodes

  enable_dns_hostnames = true  # Needed so EC2 instances get public DNS names
  enable_dns_support   = true  # Enables internal DNS resolution (required for EKS to work properly)

  tags = {
    "Name" = "eks-vpc"  # Adds a Name tag to all resources created by this module
  }
}
