output "bucket_name" {
  value = module.s3_bucket.bucket_name
}

output "public_ip" {
  value = aws_instance.demo.public_ip
}
