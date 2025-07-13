variable "user_data" {
  description = "Encoded user data"
  type        = string
  default     = "Temp string value"
}

variable "associate_public_ip_address" {
  description = "Allocation of a public IP address (required for Internet access)"
  type        = bool
  default     = false
}
