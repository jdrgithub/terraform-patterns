provider "aws" {
  region = var.region
}

module "dynamodb_table" {
  source        = "../../modules/dynamodb"
  table_name    = var.table_name
  billing_mode  = var.billing_mode
  hash_key      = var.hash_key
  hash_key_type = var.hash_key_type
  environment   = var.environment
}

module "s3_bucket" {
  source      = "../../modules/s3"
  bucket_name = var.bucket_name
  environment = var.environment
}

module "lambda_processor" {
  source               = "../../modules/lambda_s3_processor"
  lambda_function_name = "s3-batch-file-processor"
  lambda_handler       = "handler.lambda_handler"
  lambda_runtime       = "python3.12"
  source_code_path     = "${path.module}/lambda/lambda.zip"

  lambda_bucket_name   = module.s3_bucket.bucket_name
  lambda_input_prefix  = "incoming/"
  lambda_output_prefix = "processed/"
}