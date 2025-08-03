variable "table_name" {
  type        = string
  description = "DynamoDB table name"
}

variable "hash_key" {
  type        = string
  description = "Hash (partition) key for table"
}

variable "hash_key_type" {
  type        = string
  description = "Hash (partition) key type"
}

variable "billing_mode" {
  type        = string
  description = "Billing mode"
}

variable "environment" {
  type        = string
  description = "Staging environment"
}