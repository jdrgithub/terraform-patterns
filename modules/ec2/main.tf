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

resource "aws_security_group" "ec2" {
  name        = "demo-ec2-sg"
  description = "EC2 Instance Security Group"
  vpc_id      = var.vpc_id

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

resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2.id]

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx

    echo "<h1>Terraform EC2 Demo</h1>" > /usr/share/nginx/html/index.html
  EOF

  tags = {
    Name = "demo-web"
  }
}


