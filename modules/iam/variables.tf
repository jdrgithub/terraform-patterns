variable "bucket_arn" {
  description = "S3 Bucket ARN"
  type = string
  default = null 
}

variable "secret_arn" {
  description = "ARN of the Secrets Manager secret EC2 may read"
  type        = string
}