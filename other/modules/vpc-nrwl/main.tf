resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  region     = "us-east-1"

  tags = {
    Name = "vpc-${var.name_postfix}"
  }
}

resource "aws_subnet" "public" {
  for_each = {
    for subnet in var.public_subnets :
    subnet.name => subnet
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "each.key-${var.name_postfix}"
  }
}

resource "aws_subnet" "private" {
  for_each = {
    for subnet in var.private_subnets :
    subnet.name => subnet
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "each.key-${var.name_postfix}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-${var.name_postfix}"
  }
}

resource "aws_eip" "nat" {
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[var.public_subnets[0].name].id

  tags = {
    Name = "public_nat-${var.name_postfix}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public_rt-${var.name_postfix}"
  }
}

resource "aws_route_table_association" "east_public" {
  for_each = {
    for subnet in var.public_subnets :
    subnet.name => subnet
  }
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "private_rt-${var.name_postfix}"
  }
}

resource "aws_route_table_association" "private" {
  for_each = {
    for subnet in var.private_subnets :
    subnet.name => subnet
  }

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private.id
}



