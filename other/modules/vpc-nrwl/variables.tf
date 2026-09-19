variable vpc_cidr {
  type = string
} 

variable name_postfix {
  type = string
}

variable "public_subnets" {
  type = list(object({
    name = string
    cidr = string
    az   = string
  }))

}

variable "private_subnets" {
  type = list(object({
    name = string
    cidr = string
    az   = string
  }))
}