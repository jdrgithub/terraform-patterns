terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket_prefix = "jdr-tf-state-"

  # AWS setting (this is the default)
  # Can delete only if it's empty
  force_destroy = false

  # Terraform lifecycle rule
  # Reject any plan that proposes destroying this bucket
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name    = "Terraform remote state"
    Purpose = "Terraform state storage"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  # This keeps older copies whenever Terraform updates the state file.
  # If the current state is accidentally overwritten/corrupted, it can be restored.
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  # The 4 public access protections
  # If someone changes them in AWS, TF plan detects it
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

output "bucket_name" {
  description = "Name of the S3 bucket used for TF state"
  value       = aws_s3_bucket.terraform_state.id
}