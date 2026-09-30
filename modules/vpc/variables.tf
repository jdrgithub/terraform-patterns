variable "vpc_cidr" {
  description = "IPv4 CIDR block assigned to the VPC"
  type        = string
}

variable "name_prefix" {
  description = "Prefix used in Name tags for VPC resources"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet AZ to CIDR map"

  type = map(object({
    public_cidr = string
  }))

  default = {
    us-east-1a = {
      public_cidr = "10.0.1.0/24"
    }

    us-east-1b = {
      public_cidr = "10.0.2.0/24"
    }
  }
}

variable "private_subnets" {
  description = "Private subnet AZ to CIDRs map"

  type = map(object({
    private_cidr = string
  }))

  default = {
    us-east-1a = {
      private_cidr = "10.0.11.0/24"
    }

    us-east-1b = {
      private_cidr = "10.0.22.0/24"
    }
  }
}

