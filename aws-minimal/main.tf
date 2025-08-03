provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_routing_table" "public" {
  vpc_id = aws_vpc.main.id

  route = {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_routing_table_association" "public" {
  routing_table_id = aws_routing_table.public.id
  subnet_id = aws_subnet.public.id
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow SSH"
  vpc_id = aws_vpc_id.main.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "example" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true

  user_data = <<EOF
    #!/bin/bash
    yum update -y
    yum install -y nginx
    systemctl enable nginx
    systemctl start nginx
  EOF

  tags = {
    name = "example-instance"
  }

  
}

resource "aws_s3_bucket" "example_bucket" {
  bucket = "bucket-name-123"

  tags = {
    Name = "example-bucket"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.example.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAccountAccess"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:role/my-app-role"
        }
        Action    = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.example.arn}",
          "${aws_s3_bucket.example.arn}/*"
        ]
      },
      {
        Sid      = "DenyPublicAccess"
        Effect   = "Deny"
        Principal = "*"
        Action   = "s3:*"
        Resource = [
          "${aws_s3_bucket.example.arn}",
          "${aws_s3_bucket.example.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}



















