# =============================================================================
# AWS Provider Configuration
# =============================================================================
provider "aws" {
  region = var.aws_region
}

# Kubernetes provider for managing Kubernetes resources after cluster creation
provider "kubernetes" {
  host                   = aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Helm provider for installing Helm charts (add-ons)
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
