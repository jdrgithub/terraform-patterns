
# TERRAFORM STATUS COMMANDS - terraform name is contact-table
terraform state list	# List tracked resources
terraform state show module.ddb.aws_dynamodb_table.contact-table	# Show full state of the table

# AWS COMMANDS - table is contacts
aws dynamodb list-tables  # list tables 
aws dynamodb describe-table --table-name contacts  #	View live table metadata/status