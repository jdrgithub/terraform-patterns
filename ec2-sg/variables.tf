variable "vpc_cidr" {
  description = "IPv4 CIDR block for SG Rules"
  type        = string
}

variable "sg_cidr" {
  description = "IPv4 CIDR block for SG Rules"
  type        = string
}

variable "name_prefix" {
  description = "Prefix used in Name tags for VPC resources"
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

# variable "public_subnets" {
#   description = "Public subnet AZ to CIDR map"

#   type = map(object({
#     public_cidr  = string
#   }))
# }

# variable "private_subnets" {
#   description = "Private subnet AZ to CIDRs map"

#   type = map(object({
#     private_cidr  = string
#   }))
# }