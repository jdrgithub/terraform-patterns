
# s3_handler.py

from processor import resize_image

def lambda_handler(event, context):
    try:
        record = event["Records"][0]
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]

        resize_image(bucket, key)

        return {"statusCode": 200, "body": "Success"}
    except Exception as e:
        print(f"Error: {e}")
        raise  # Will trigger async retry if not caught and handled
