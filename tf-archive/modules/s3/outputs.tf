output "bucket_name" {
  description = "Bucket name"
  value       = aws_s3_bucket.this.bucket # The S3 bucket TF sees in state
}

output "bucket_arn" {
  description = "S3 bucket arn"
  value       = aws_s3_bucket.this.arn # The ARN TF sees in state
}