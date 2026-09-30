variable "sg_cidr" {
  description = "IPv4 CIDR block for SG Rules"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "instance_profile" {
  description = "IAM instance profile for EC2"
  type = string
  default = null
}

variable "subnet_id" {
  description = "ID for the EC2 subnet"
  type        = string
}

# variable "public_subnets" {
#   description = "Public subnet CIDRs organizaed by Availability Zone"

#   type = map(
#     object(
#       {
#         public_cidr  = string
#       }
#     )
#   )
# }