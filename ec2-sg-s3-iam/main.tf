module "s3_bucket" {
  source          = "../modules/s3"
  caller_identity = module.iam.caller_identity
  upload_file     = var.upload_file
}

module "iam" {
  source     = "../modules/iam"
  bucket_arn = module.s3_bucket.bucket_arn
}

module "vpc" {
  source = "../modules/vpc"

  vpc_cidr    = var.vpc_cidr
  name_prefix = var.name_prefix
  public_subnets     = var.public_subnets
  private_subnets = var.private_subnets
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "free-tier-eligible"
    values = ["true"] # needs to be collection of strings not bool
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

}

data "aws_subnet" "public" {
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["terraform-demo-public-subnet-us-east-1a"]
  }
}

resource "aws_security_group" "ec2" {
  name        = "demo-ec2-sg"
  description = "EC2 Instance Security Group"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "demo-ec2-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = var.sg_cidr
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_http" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = var.sg_cidr
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = var.sg_cidr
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ec2_connect" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = var.ec2_connect_ip
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_ec2_connect" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = var.ec2_connect_ip
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_launch_template" "web" {
  name_prefix            = "web-"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  # vpc_security_groups_ids doesn't work.  add below to network_interfaces
  # https://github.com/hashicorp/terraform-provider-aws/issues/4570 
  # vpc_security_group_ids = [aws_security_group.ec2.id] 
  
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.ec2.id]
  }

  iam_instance_profile {
    name = module.iam.instance_profile_name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx

    echo "<h1>Terraform EC2 Demo</h1>" > /usr/share/nginx/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "web"
    }
  }
}

resource "aws_autoscaling_group" "web" {
  name = "web-asg"

  min_size         = 1
  max_size         = 2
  desired_capacity = 2

  vpc_zone_identifier = [
    module.vpc.subnet_ids.public.us-east-1a,
    module.vpc.subnet_ids.public.us-east-1b
  ]

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }
}






