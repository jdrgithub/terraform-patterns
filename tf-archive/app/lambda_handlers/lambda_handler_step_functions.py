# Lambda runs as a task in a Step Functions workflow, often expecting structured JSON in and out.
'''
Why it's different:
Step Functions expects clean JSON in/out

Failures don’t throw exceptions unless you want to catch them in a Catch block

Use ResultPath and OutputPath in your state definition to control JSON shape
'''

def lambda_handler(event, context):
    try:
        # Expecting well-formed JSON input
        user_id = event["user_id"]
        print(f"Step processing user {user_id}")

        # Simulate processing
        return {
            "status": "success",
            "user_id": user_id
        }

    except KeyError as e:
        return {
            "status": "error",
            "reason": f"Missing key: {e}"
        }
