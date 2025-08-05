import boto3

# Initialize Dynamodb client
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

# Reference your table
table = dynamodb.Table('contact-table')

# Put and item
table.put_item(Item={'name': 'Alice', 'phone': '333-333-3333'})

# Get the item
response = table.get_item(Key={'name': 'Alice'})
item = response.get('Item')

# Print item
print(item)

