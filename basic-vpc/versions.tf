terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket       = "jdr-tf-state-b2aee5bfcf8bd67ef564816936"
    key          = "basic-vpc/terraform-tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

