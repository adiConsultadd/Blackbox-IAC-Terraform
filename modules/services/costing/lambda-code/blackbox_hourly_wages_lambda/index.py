def handler(event, context):
    print("Hello from blackbox_hourly_wages_lambda!")
    return {
        "statusCode": 200,
        "body": "Hello from blackbox_hourly_wages_lambda!"
    }
