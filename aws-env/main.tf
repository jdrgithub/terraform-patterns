
data "aws_ami" "dev_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon Linux
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

data "aws_security_group" "default-sg" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

resource "aws_launch_template" "dev_launch_template" {
  name_prefix   = "dev_lt-"
  instance_type = "t2.micro"
  image_id      = data.aws_ami.dev_ami.id
  user_data     = base64encode(var.user_data)

  network_interfaces {
    associate_carrier_ip_address = var.associate_public_ip_address
    security_groups              = [data.aws_security_group.default-sg.id]
  }



}

resource "aws_autoscaling_group" "dev_autoscaling_group" {
  desired_capacity          = 1
  max_size                  = 1
  min_size                  = 1
  health_check_type         = "EC2"
  health_check_grace_period = 300
  vpc_zone_identifier       = module.vpc.public_subnets

  launch_template {
    id      = aws_launch_template.dev_launch_template.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "dev-web-instance"
    propagate_at_launch = true
  }
}