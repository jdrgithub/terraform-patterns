output "bucket_name" {
  description = "Bucket name"
  value = var.bucket_name
}

output "bucket_arn" {
  description = "S3 bucket arn"
  value = aws_s3_bucket.this.arn
}