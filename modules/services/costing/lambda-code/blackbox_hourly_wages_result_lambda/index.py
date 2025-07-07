def handler(event, context):
    print("Hello from blackbox_hourly_wages_result_lambda!")
    return {
        "statusCode": 200,
        "body": "Hello from blackbox_hourly_wages_result_lambda!"
    }
