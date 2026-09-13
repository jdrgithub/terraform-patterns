variable "vpc_cidr" {
  description = "IPv4 CIDR block assigned to the VPC"
  type        = string
}

variable "name_prefix" {
  description = "Prefix used in Name tags for VPC resources"
  type        = string
}

variable "subnets" {
  description = "Public and private sugnet CIDRs organized by Availability Zone"

  type = map(object({
    public_cidr  = string
    private_cidr = string
  }))
}