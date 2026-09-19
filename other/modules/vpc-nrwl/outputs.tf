output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "output_ids" {
  description = "ID for the public and private subnets"

  value = {
    public_subnets = {
      for name, id in aws_subnet.public: name => id 
    }
    private_subnets = {
      for name, id in aws_subnet.private: name => id
    }
  }
}
