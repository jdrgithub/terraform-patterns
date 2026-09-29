resource "aws_secretsmanager_secret" "this" {
  name        = var.name
  description = var.description

  recovery_window_in_days = var.recovery_window_in_days

  tags = var.tags
}

# resource "aws_secretsmanager_secret_version" "this" {
#   secret_id     = aws_secretsmanager_secret.this.id
#   secret_string = "demo-api-key-12345"
# }

# APPLY WITH CLI OUTSIDE OF TF
# aws secretsmanager put-secret-value \
#   --secret-id dev/demo-app/api-key \
#   --secret-string 'demo-api-key-67890'

# aws secretsmanager get-secret-value \
#   --secret-id dev/demo-app/api-key \
#   --query SecretString \
#   --output text

