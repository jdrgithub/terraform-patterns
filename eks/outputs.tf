# Output the EKS cluster name
output "cluster_name" {
  description = "The name of the EKS cluster"
  value = aws_eks_cluster.cluster.name
}

# Output the Kubernetes API endpoint (needed for kubectl access)
output "cluster_endpoint" {
  description = "Public URL of the Kubernetes control plane"
  value = aws_eks_cluster.cluster.endpoint
}

# Output the certificate used to authenticate the API server
output "cluster_certificate_authority_data" {
  description = "TLS certificate (Base64-encoded) for verifying th eKubernetes API"
  value = aws_eks_cluster.cluster.endpoint
}

# Output the ARN of the worker IAM role (for debugging or policy attachment)
output "worker_iam_role_arn" {
  description = "IAM role user by the EKS worker nodes (EC2 instances)"
  value = aws_iam_role.worker.arn
}