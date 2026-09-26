variable "aws_region" {
  description = "AWS region where the VPC will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block assigned to the VPC"
  type        = string
}

variable "name_prefix" {
  description = "Prefix used in Name tages for VPC resources"
  type        = string
}

variable "subnets" {
  description = "Public and private subnet CIDRs organizaed by Availability Zone"

  type = map(
    object(
      {
        public_cidr  = string
        private_cidr = string
      }
    )
  )
}