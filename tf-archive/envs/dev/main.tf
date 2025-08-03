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
