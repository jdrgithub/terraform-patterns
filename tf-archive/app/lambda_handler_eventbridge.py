# Used for event-driven architectures, often with detail-type routing.

'''
# Example Event
{
  "source": "myapp.orders",
  "detail-type": "OrderPlaced",
  "detail": {
    "order_id": "abc123"
  }
}
'''




def lambda_handler(event, context):
    try:
        detail_type = event.get("detail-type")
        detail = event.get("detail", {})

        if detail_type == "UserCreated":
            user_id = detail.get("user_id")
            print(f"Handle new user: {user_id}")
            # Call your actual logic here
        elif detail_type == "OrderPlaced":
            order_id = detail.get("order_id")
            print(f"Process order: {order_id}")
        else:
            print(f"Unhandled event type: {detail_type}")

    except Exception as e:
        print(f"Error processing EventBridge event: {e}")
        raise
