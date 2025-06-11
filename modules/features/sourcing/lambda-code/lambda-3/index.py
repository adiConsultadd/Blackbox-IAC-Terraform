def handler(event, context):
    print("Hello World from Lambda‑3")
    return {
        "statusCode": 200,
        "body": "Hello from Lambda‑3!"
    }