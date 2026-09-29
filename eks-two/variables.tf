# AWS region to deploy all resources into
variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

# EKS cluster name (also for tags)
variable "cluster_name" {
  description = "Name for the EKS cluster"
  type        = string
  default     = "my-eks-cluster"
}

# Kubernetes version to deploy that is supported by EKS
variable "kubernetes_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
  default     = "1.28" # Latest supported version
}

# EC2 instance type for worker nodes
variable "instance_type" {
  description = "EC2 instance type used by EKS node group"
  type        = string
  default     = "t3.medium" # Good balance of performance and cost
}

# Minimum number of worker nodes in the node group
variable "min_size" {
  description = "Minimum number of nodes to scale down to"
  type        = number
  default     = 2
}

# Desired number of worker nodes in the node group
variable "desired_size" {
  description = "Initial desired number of nodes"
  type        = number
  default     = 2
}

# Maximum number of worker nodes in the node group
variable "max_size" {
  description = "Maximum number of nodes to scale up to"
  type        = number
  default     = 3
}
