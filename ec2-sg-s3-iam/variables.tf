variable "upload_file" {
  description = "File to upload"
  default     = "./test.txt"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for SG Rules"
  type        = string
}

variable "sg_cidr" {
  description = "IPv4 CIDR block for SG Rules"
  type        = string
}

variable "ec2_connect_ip" {
  description = "IPv4 CIDR block for EC2 Instance Connect Service IP"
  type        = string
}

variable "name_prefix" {
  description = "Prefix used in Name tages for VPC resources"
  type        = string
}

variable "public_subnets" {
  description = "Private subnet CIDRs organizaed by Availability Zone"

  type = map(
    object(
      {
        public_cidr  = string
      }
    )
  )
}

variable "private_subnets" {
  description = "Private subnet CIDRs organizaed by Availability Zone"

  type = map(
    object(
      {
        private_cidr  = string
      }
    )
  )
}
