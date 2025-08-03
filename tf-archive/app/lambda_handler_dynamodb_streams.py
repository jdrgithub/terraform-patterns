# Triggered when data is inserted/modified/deleted in a table.
'''
Records use DynamoDB JSON format (S for string, N for number, etc.)

Use boto3.dynamodb.types.TypeDeserializer() if you want to convert to plain Python dicts

You may process multiple records per invocation
'''


import boto3
import base64

def lambda_handler(event, context):
    for record in event["Records"]:
        try:
            event_name = record["eventName"]  # INSERT, MODIFY, REMOVE
            keys = record["dynamodb"].get("Keys")
            new_image = record["dynamodb"].get("NewImage")

            if event_name == "INSERT":
                print(f"New item inserted: {new_image}")
            elif event_name == "MODIFY":
                print(f"Item updated: {new_image}")
            elif event_name == "REMOVE":
                print(f"Item deleted: {keys}")
            else:
                print(f"Unhandled event: {event_name}")
        except Exception as e:
            print(f"Error in DynamoDB stream processing: {e}")
            raise
