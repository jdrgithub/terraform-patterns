# Handles a REST API POST request
# api_handler.py

import json
from processor import create_user

def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body", "{}"))
        name = body.get("name")

        if not name:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Missing 'name'"})
            }

        result = create_user(name)

        return {
            "statusCode": 201,
            "body": json.dumps({"id": result["user_id"]})
        }
    except Exception as e:
        print(f"Unhandled error: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Internal server error"})
        }
