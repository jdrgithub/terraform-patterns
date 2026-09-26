variable "upload_file" {
  description = "File to upload"
  default     = "./test.txt"
}

variable "caller_identity" {
  description = "AWS ID"
  type        = string
}