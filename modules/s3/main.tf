resource "random_integer" "random_num" {
  min = 1000
  max = 9999
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "${var.caller_identity}-${random_integer.random_num.result}-bucket"
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.my_bucket.bucket
  key    = "dev/${var.upload_file}"
  source = "./${var.upload_file}" # ${path.module} us the fsystem path of the module where he current .tf lifes

  # Hash the file contents so Terraform detects changes
  # recalculates filemd5("./test.txt") when it evaluates the configuration
  # compares that value against the etag value recorded for the resource in the Terraform state
  # if they differ, Terraform sees a change
  etag = filemd5("${var.upload_file}")
}