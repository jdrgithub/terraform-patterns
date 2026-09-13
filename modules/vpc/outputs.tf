output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "IDs of the public and private subnets"

  value = {
    public = {
      for az, subnet in aws_subnet.public : az => subnet.id
    }

    private = {
      for az, subnet in aws_subnet.private : az => subnet.id
    }
  }
}