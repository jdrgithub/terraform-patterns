resource "aws_dynamodb_table" "contact-table" {
  name         = var.table_name
  hash_key     = var.hash_key
  billing_mode = var.billing_mode

  attribute {
    name = var.hash_key
    type = var.hash_key_type
  }

  tags = {
    Name        = var.table_name
    Environment = var.environment
  }

}
