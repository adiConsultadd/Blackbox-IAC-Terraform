def handler(event, context):
    print("Hello World from Lambda‑1")
    return {
        "statusCode": 200,
        "body": "Hello from Lambda‑1!"
    }