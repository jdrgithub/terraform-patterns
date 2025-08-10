# Output the EKS cluster name
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.cluster.name
}

# Output the Kubernetes API endpoint (needed for kubectl access)
output "cluster_endpoint" {
  description = "Public URL of the Kubernetes control plane"
  value       = aws_eks_cluster.cluster.endpoint
}

# Output the certificate used to authenticate the API server
output "cluster_certificate_authority_data" {
  description = "TLS certificate (Base64-encoded) for verifying the Kubernetes API"
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
}

# Output the ARN of the node group IAM role
output "node_group_iam_role_arn" {
  description = "IAM role used by the EKS worker nodes (EC2 instances)"
  value       = aws_iam_role.eks_node_group.arn
}

# Output VPC information
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.eks_vpc.id
}

# Output subnet information
output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

# Output cluster version
output "cluster_version" {
  description = "The Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.cluster.version
}

# Output node group information
output "node_group_name" {
  description = "The name of the EKS node group"
  value       = aws_eks_node_group.main.node_group_name
}

# Output kubectl configuration command
output "configure_kubectl" {
  description = "Command to configure kubectl for the EKS cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.cluster.name}"
}