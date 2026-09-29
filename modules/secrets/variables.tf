variable "name" {
  type = string
}

variable "description" {
  type    = string
  default = null
}

variable "recovery_window_in_days" {
  type    = string
  default = 7
}

variable "tags" {
  type    = map(string)
  default = {}
}