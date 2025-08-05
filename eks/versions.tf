terraform {
  required_version = ">= 1.5.0"
  # Enforces the minimum Terraform version; ensures compatibility with newer syntax and provider behavior

  required_providers {
    aws = {
      source  = "hashicorp/aws" # Official AWS provider from the Terraform Registry
      version = "~> 5.0"        # Use any version >= 5.0.0 and < 6.0.0
    }
    kubernetes = {
      source  = "hashicorp/kubernetes" # Official Kubernetes provider for interacting with the cluster
      version = "~> 2.30"              # Compatible with Terraform 1.x and Kubernetes 1.29+
    }
  }

  backend "local" {
    path = "terraform.tfstate"
    # Stores Terraform state locally in a file — good for quick setups
    # In production, use "s3" + "dynamodb" for shared remote state and locking
  }
}
