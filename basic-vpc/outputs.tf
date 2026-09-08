output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "IDs of the public and private subnets"

  value = {
    public  = aws_subnet.public.id
    private = aws_subnet.private.id
  }
}