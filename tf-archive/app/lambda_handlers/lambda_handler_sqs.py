# Processes a batch of messages from SQS.

# sqs_handler.py

from processor import handle_message

def lambda_handler(event, context):
    for record in event["Records"]:
        try:
            body = record["body"]
            handle_message(body)
        except Exception as e:
            print(f"Failed to process message: {record['messageId']} - {e}")
            # Let it throw so Lambda retries or moves it to DLQ
            raise
