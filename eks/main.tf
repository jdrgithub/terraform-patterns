# =============================================================================
# EKS Cluster
# =============================================================================
# Create EKS cluster
resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  # VPC configuration
  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]  # Allow public access from anywhere
  }

  # Enable control plane logging to CloudWatch
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_subnet.private,
    aws_subnet.public
  ]

  tags = {
    Name = var.cluster_name
  }
}

# =============================================================================
# EKS Node Group
# =============================================================================
# Create managed node group with 2-3 t-class instances
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "main-node-group"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = aws_subnet.private[*].id  # Place nodes in private subnets
  version         = var.kubernetes_version

  # Instance configuration
  instance_types = [var.instance_type]
  capacity_type  = "ON_DEMAND"

  # Scaling configuration
  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  # Update configuration
  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_read_only_policy
  ]

  tags = {
    Name = "${var.cluster_name}-node-group"
  }
}

# =============================================================================
# EKS Add-ons
# =============================================================================
# VPC CNI Add-on (required for pod networking)
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "vpc-cni"
  addon_version = "v1.16.0-eksbuild.1"  # Latest compatible version

  depends_on = [aws_eks_node_group.main]
}

# CoreDNS Add-on (required for DNS resolution)
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "coredns"
  addon_version = "v1.10.1-eksbuild.1"  # Latest compatible version

  depends_on = [aws_eks_node_group.main]
}

# kube-proxy Add-on (required for service networking)
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "kube-proxy"
  addon_version = "v1.28.1-eksbuild.1"  # Latest compatible version

  depends_on = [aws_eks_node_group.main]
}

# EBS CSI Driver Add-on (for persistent volumes)
resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "aws-ebs-csi-driver"
  addon_version = "v2.20.0-eksbuild.1"  # Latest compatible version

  depends_on = [aws_eks_node_group.main]
}

# =============================================================================
# aws-auth ConfigMap
# =============================================================================
# Create aws-auth ConfigMap to allow EKS node group to join the cluster
resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.eks_node_group.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes"
        ]
      }
    ])
  }

  depends_on = [aws_eks_cluster.cluster]
}

# =============================================================================
# Metrics Server
# =============================================================================
# Install Metrics Server for resource monitoring
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "6.3.0"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  depends_on = [aws_eks_cluster.cluster]
}

# =============================================================================
# AWS Load Balancer Controller
# =============================================================================
# Install AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.6.1"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.cluster.name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller.arn
  }

  depends_on = [aws_eks_cluster.cluster]
}

# =============================================================================
# Cluster Autoscaler
# =============================================================================
# Install Cluster Autoscaler
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.35.0"

  set {
    name  = "autoDiscovery.clusterName"
    value = aws_eks_cluster.cluster.name
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cluster_autoscaler.arn
  }

  depends_on = [aws_eks_cluster.cluster]
}
