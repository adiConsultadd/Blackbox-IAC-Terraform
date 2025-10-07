#############################################################
# 6. WebSocket API Gateway
#############################################################
resource "aws_apigatewayv2_api" "websocket_api" {
  name                       = "${var.project_name}-${var.environment}-batch-processing-websocket-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

# --- Integrations for WebSocket Routes ---
resource "aws_apigatewayv2_integration" "ws_connect_integration" {
  api_id           = aws_apigatewayv2_api.websocket_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = module.lambda["batch-processing-ws-connect"].invoke_arn
}

resource "aws_apigatewayv2_integration" "ws_disconnect_integration" {
  api_id           = aws_apigatewayv2_api.websocket_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = module.lambda["batch-processing-ws-disconnect"].invoke_arn
}

resource "aws_apigatewayv2_integration" "ws_default_integration" {
  api_id           = aws_apigatewayv2_api.websocket_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = module.lambda["batch-processing-ws-default"].invoke_arn
}

# --- Routes for WebSocket ---
resource "aws_apigatewayv2_route" "ws_connect_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.ws_connect_integration.id}"
}

resource "aws_apigatewayv2_route" "ws_disconnect_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.ws_disconnect_integration.id}"
}

resource "aws_apigatewayv2_route" "ws_default_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.ws_default_integration.id}"
}

# --- Deployment and Stage ---
resource "aws_apigatewayv2_deployment" "websocket_deployment" {
  api_id = aws_apigatewayv2_api.websocket_api.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_apigatewayv2_integration.ws_connect_integration.id,
      aws_apigatewayv2_integration.ws_disconnect_integration.id,
      aws_apigatewayv2_integration.ws_default_integration.id,
    ]))
  }
  lifecycle { create_before_destroy = true }
}

resource "aws_apigatewayv2_stage" "websocket_stage" {
  api_id        = aws_apigatewayv2_api.websocket_api.id
  name          = var.environment
  deployment_id = aws_apigatewayv2_deployment.websocket_deployment.id
}

# --- Lambda Permissions for WebSocket ---
resource "aws_lambda_permission" "allow_ws_connect" {
  statement_id  = "AllowAPIGWStoInvokeConnect"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda["batch-processing-ws-connect"].lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*/$connect"
}

resource "aws_lambda_permission" "allow_ws_disconnect" {
  statement_id  = "AllowAPIGWStoInvokeDisconnect"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda["batch-processing-ws-disconnect"].lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*/$disconnect"
}

resource "aws_lambda_permission" "allow_ws_default" {
  statement_id  = "AllowAPIGWStoInvokeDefault"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda["batch-processing-ws-default"].lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*/$default"
}