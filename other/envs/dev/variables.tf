variable "vpc_cidr_a" {
  type = string
}

variable "vpc_cidr_b" {
  type = string
}

variable "public_subnets_one" {
  type = list(object({
    name = string
    cidr = string
    az   = string
  }))

}

variable "private_subnets_one" {
  type = list(object({
    name = string
    cidr = string
    az   = string
  }))
}

variable "public_subnets_two" {
  type = list(object({
    name = string
    cidr = string
    az   = string
  }))

}

variable "private_subnets_two" {
  type = list(object({
    name = string
    cidr = string
    az   = string
  }))
}


variable "enable_peering" {
  type = bool
}

variable "name_postfix_a" {
  type = string
}

variable "name_postfix_b" {
  type = string
}