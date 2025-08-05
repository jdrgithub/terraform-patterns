variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "lambda_handler" {
  description = "The function entrypoint (e.g. handler.lambda_handler)"
  type        = string
}

variable "lambda_runtime" {
  description = "Runtime to use (e.g. handler.lambda_handler)"
  type        = string
}

variable "source_code_path" {
  description = "Path to the local zip file of the Lambda"
  type        = string
}

variable "lambda_bucket_name" {
  description = "Name of the existing S3 bucket that triggers thsi Lambda"
  type        = string
}

variable "lambda_input_prefix" {
  description = "Prefix to filter incoming files (e.g. incoming/)"
  type        = string
}

variable "lambda_output_prefix" {
  description = "Prefix to save processed file (e.g. processed/)"
}