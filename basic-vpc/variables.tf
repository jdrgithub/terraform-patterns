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

variable "public_subnet_cidr" {
  description = "IPV4 CIDR block assigned to the public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "IPv4 CIDR block assigned to the public subnet"
  type        = string
}

variable "availability_zone" {
  description = "Availability Zone used by the public and private subnets"
  type        = string
}