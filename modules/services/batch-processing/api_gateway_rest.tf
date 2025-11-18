#############################################################
# 5. REST API Gateway
#############################################################

# CORS Configuration Locals
locals {
  cors_resources = {
    batches_resource = {
      id      = aws_api_gateway_resource.batches_resource.id,
      methods = "GET,POST,OPTIONS" # Methods available on /batches
    },
    validation_resource = {
      id      = aws_api_gateway_resource.validation_resource.id,
      methods = "POST,OPTIONS" # Methods available on /batches/validation
    },
    batch_id_resource = {
      id      = aws_api_gateway_resource.batch_id_resource.id,
      methods = "GET,OPTIONS,PATCH" # Methods available on /batches/{batch_id}
    },
    start_resource = {
      id      = aws_api_gateway_resource.start_resource.id,
      methods = "POST,OPTIONS" # Methods available on /batches/content/start
    },
    source_id_resource = {
      id      = aws_api_gateway_resource.source_id_resource.id,
      methods = "DELETE,OPTIONS"
    },
    agency_references_resource = {
      id      = aws_api_gateway_resource.agency_references_resource.id,
      methods = "GET,POST,OPTIONS" # Methods available on /agency-references
    },
    feedback_resource = {
      id      = aws_api_gateway_resource.feedback_resource.id,
      methods = "POST,OPTIONS" # Methods available on /feedback
    }
  }
}

# Define the main API Gateway
resource "aws_api_gateway_rest_api" "rest_api" {
  name = "${var.project_name}-${var.environment}-batch-processing-rest-api"
  endpoint_configuration {
    types = ["REGIONAL"]
  }

  binary_media_types = [
    "image/png",
    "image/jpeg",
    "image/jpg",
    "image/gif",
    "multipart/form-data",
    "image/svg+xml"
  ]
}

# Create the Lambda Authorizer
resource "aws_api_gateway_authorizer" "lambda_authorizer" {
  name                   = "${var.project_name}-${var.environment}-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.rest_api.id
  authorizer_uri         = module.lambda["batch-processing-authorizer"].invoke_arn
  authorizer_credentials = aws_iam_role.apigw_authorizer_invocation_role.arn
  type                   = "TOKEN"
  identity_source        = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 3600
}

# IAM Role to allow API Gateway to invoke the authorizer Lambda
resource "aws_iam_role" "apigw_authorizer_invocation_role" {
  name = "${var.project_name}-${var.environment}-apigw-authorizer-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "apigateway.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "apigw_authorizer_invocation_policy" {
  name = "${var.project_name}-${var.environment}-apigw-authorizer-policy"
  role = aws_iam_role.apigw_authorizer_invocation_role.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action   = "lambda:InvokeFunction",
      Effect   = "Allow",
      Resource = module.lambda["batch-processing-authorizer"].lambda_arn
    }]
  })
}

# Permission for the API Gateway to invoke the authorizer Lambda
resource "aws_lambda_permission" "allow_authorizer" {
  statement_id  = "AllowAPIGatewayToInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda["batch-processing-authorizer"].lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.rest_api.id}/authorizers/${aws_api_gateway_authorizer.lambda_authorizer.id}"
}

resource "aws_api_gateway_model" "feedback_model" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  name          = "FeedbackModel"
  description   = "Schema for the POST /feedback request body"
  content_type  = "application/json"
  schema = jsonencode({
    "$schema"    = "http://json-schema.org/draft-04/schema#"
    "title"      = "FeedbackPayload"
    "type"       = "object"
    "properties" = {
      "promptData" = {
        "type" = "string"
      }
    }
    "required" = ["promptData"]
  })
}

# Resource: /batches (Level 1)
resource "aws_api_gateway_resource" "batches_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "batches"
}

# Resource: /validation (Level 2, nested under /batches)
resource "aws_api_gateway_resource" "validation_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_resource.batches_resource.id
  path_part   = "validation"
}

# Method: POST on /batches/validation
resource "aws_api_gateway_method" "post_validation" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.validation_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id
  request_models = {
    "application/json" = "Empty"
  }
}

# Integration for the POST method
resource "aws_api_gateway_integration" "post_validation_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.validation_resource.id
  http_method             = aws_api_gateway_method.post_validation.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda["batch-processing-validation-pre-process"].invoke_arn
}

# --- NEW Endpoint: GET /batches ---
resource "aws_api_gateway_method" "get_batches" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.batches_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id
}

resource "aws_api_gateway_integration" "get_batches_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.batches_resource.id
  http_method             = aws_api_gateway_method.get_batches.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda["batch-processing-content-api-handler"].invoke_arn
}

# --- NEW Endpoint: GET /batches/{batch_id} ---
resource "aws_api_gateway_resource" "batch_id_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_resource.batches_resource.id
  path_part   = "{batch_id}"
}

resource "aws_api_gateway_method" "get_batch_by_id" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.batch_id_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id
}

resource "aws_api_gateway_integration" "get_batch_by_id_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.batch_id_resource.id
  http_method             = aws_api_gateway_method.get_batch_by_id.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda["batch-processing-content-api-handler"].invoke_arn
}

# --- NEW Endpoint: POST /batches ---
resource "aws_api_gateway_method" "post_batches" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.batches_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id
}

resource "aws_api_gateway_integration" "post_batches_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.batches_resource.id
  http_method             = aws_api_gateway_method.post_batches.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda["batch-processing-content-api-handler"].invoke_arn
}

resource "aws_api_gateway_method_response" "post_batches_200" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.batches_resource.id
  http_method = aws_api_gateway_method.post_batches.http_method
  status_code = "200"
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = true }
  response_models = {
    "application/json" = "Empty"
  }
}

# --- NEW Endpoint: PATCH /batches/{batch_id} ---
resource "aws_api_gateway_method" "patch_batch_by_id" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.batch_id_resource.id
  http_method   = "PATCH"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id
}

resource "aws_api_gateway_integration" "patch_batch_by_id_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.batch_id_resource.id
  http_method             = aws_api_gateway_method.patch_batch_by_id.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda["batch-processing-content-api-handler"].invoke_arn
}

resource "aws_api_gateway_method_response" "patch_batch_by_id_200" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.batch_id_resource.id
  http_method = aws_api_gateway_method.patch_batch_by_id.http_method
  status_code = "200"
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = false }
  response_models = {
    "application/json" = "Empty"
  }
}

# --- NEW Endpoint: DELETE /batches/{batch_id}/{source_id} ---
resource "aws_api_gateway_resource" "source_id_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_resource.batch_id_resource.id
  path_part   = "{source_id}"
}

resource "aws_api_gateway_method" "delete_source_by_id" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.source_id_resource.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id
}

resource "aws_api_gateway_integration" "delete_source_by_id_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.source_id_resource.id
  http_method             = aws_api_gateway_method.delete_source_by_id.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda["batch-processing-content-api-handler"].invoke_arn
}

resource "aws_api_gateway_method_response" "delete_source_by_id_200" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.source_id_resource.id
  http_method = aws_api_gateway_method.delete_source_by_id.http_method
  status_code = "200"
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = true }
  response_models = {
    "application/json" = "Empty"
  }
}

# --- NEW Endpoint: POST /batches/content/start ---
resource "aws_api_gateway_resource" "content_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_resource.batches_resource.id
  path_part   = "content"
}

resource "aws_api_gateway_resource" "start_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_resource.content_resource.id
  path_part   = "start"
}

resource "aws_api_gateway_method" "post_start" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.start_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id
}
  
resource "aws_api_gateway_integration" "post_start_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.start_resource.id
  http_method             = aws_api_gateway_method.post_start.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda["batch-processing-content-api-handler"].invoke_arn
}

# --- NEW Endpoint: /agency-references ---
resource "aws_api_gateway_resource" "agency_references_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_resource.batches_resource.id
  path_part   = "agency-references"
}

resource "aws_api_gateway_method" "get_agency_references" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.agency_references_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id
}

resource "aws_api_gateway_integration" "get_agency_references_integration" {
  rest_api_id               = aws_api_gateway_rest_api.rest_api.id
  resource_id               = aws_api_gateway_resource.agency_references_resource.id
  http_method               = aws_api_gateway_method.get_agency_references.http_method
  integration_http_method = "POST"
  type                      = "AWS_PROXY"
  uri                       = module.lambda["batch-processing-content-api-handler"].invoke_arn
}

resource "aws_api_gateway_method" "post_agency_references" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.agency_references_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id
}

resource "aws_api_gateway_integration" "post_agency_references_integration" {
  rest_api_id               = aws_api_gateway_rest_api.rest_api.id
  resource_id               = aws_api_gateway_resource.agency_references_resource.id
  http_method               = aws_api_gateway_method.post_agency_references.http_method
  integration_http_method = "POST"
  type                      = "AWS_PROXY"
  uri                       = module.lambda["batch-processing-content-api-handler"].invoke_arn
}

# --- NEW Endpoint: POST /feedback (at root) ---
resource "aws_api_gateway_resource" "feedback_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "feedback"
}

resource "aws_api_gateway_method" "post_feedback" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.feedback_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id

  request_models = {
    "application/json" = aws_api_gateway_model.feedback_model.name
  }
}

resource "aws_api_gateway_integration" "post_feedback_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.feedback_resource.id
  http_method             = aws_api_gateway_method.post_feedback.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda["feedback"].invoke_arn 
}

################################################################################
# CORS OPTIONS Method and Mock Integration
################################################################################

resource "aws_api_gateway_method" "cors_options" {
  for_each      = local.cors_resources
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = each.value.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cors_options" {
  for_each    = local.cors_resources
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = each.value.id
  http_method = aws_api_gateway_method.cors_options[each.key].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "cors_options_200" {
  for_each    = local.cors_resources
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = each.value.id
  http_method = aws_api_gateway_method.cors_options[each.key].http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Credentials" = true,
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "cors_options_200" {
  for_each    = local.cors_resources
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = each.value.id
  http_method = aws_api_gateway_method.cors_options[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'${each.value.methods}'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'",
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
  }

  depends_on = [aws_api_gateway_method_response.cors_options_200, aws_api_gateway_integration.cors_options]
}

################################################################################
# CORS Headers for Existing Methods
################################################################################

resource "aws_api_gateway_method_response" "post_validation_200" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.validation_resource.id
  http_method   = aws_api_gateway_method.post_validation.http_method
  status_code   = "200"
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = true }
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "get_batches_200" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.batches_resource.id
  http_method   = aws_api_gateway_method.get_batches.http_method
  status_code   = "200"
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = true }
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "get_batch_by_id_200" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.batch_id_resource.id
  http_method   = aws_api_gateway_method.get_batch_by_id.http_method
  status_code   = "200"
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = false }
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "post_start_200" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.start_resource.id
  http_method   = aws_api_gateway_method.post_start.http_method
  status_code   = "200"
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = true }
  response_models = {
    "application/json" = "Empty"
  }

}

resource "aws_api_gateway_method_response" "get_agency_references_200" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.agency_references_resource.id
  http_method   = aws_api_gateway_method.get_agency_references.http_method
  status_code   = "200"
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = true }
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "post_agency_references_200" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.agency_references_resource.id
  http_method   = aws_api_gateway_method.post_agency_references.http_method
  status_code   = "200"
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = true }
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "post_feedback_200" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.feedback_resource.id
  http_method = aws_api_gateway_method.post_feedback.http_method
  status_code = "200"
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = true }
  response_models = {
    "application/json" = "Empty"
  }
}

# Deployment of the API
resource "aws_api_gateway_deployment" "rest_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  triggers = {
    redeployment = sha1(jsonencode([
    aws_api_gateway_resource.batches_resource.id,
    aws_api_gateway_resource.validation_resource.id,
    aws_api_gateway_method.post_validation.id,
    aws_api_gateway_integration.post_validation_integration.id,
    aws_api_gateway_authorizer.lambda_authorizer.id,
    aws_api_gateway_method.get_batches.id,
    aws_api_gateway_integration.get_batches_integration.id,
    aws_api_gateway_resource.batch_id_resource.id,
    aws_api_gateway_method.get_batch_by_id.id,
    aws_api_gateway_integration.get_batch_by_id_integration.id,
    aws_api_gateway_resource.content_resource.id,
    aws_api_gateway_resource.start_resource.id,
    aws_api_gateway_method.post_start.id,
    aws_api_gateway_integration.post_start_integration.id,
    values(aws_api_gateway_method.cors_options)[*].id,
    values(aws_api_gateway_integration_response.cors_options_200)[*].id,
    aws_api_gateway_method.patch_batch_by_id.id,
    aws_api_gateway_integration.patch_batch_by_id_integration.id,
    aws_api_gateway_resource.source_id_resource.id,
    aws_api_gateway_method.delete_source_by_id.id,
    aws_api_gateway_integration.delete_source_by_id_integration.id,
    aws_api_gateway_method.post_batches.id,
    aws_api_gateway_integration.post_batches_integration.id,
    aws_api_gateway_resource.agency_references_resource.id,
    aws_api_gateway_method.get_agency_references.id,
    aws_api_gateway_integration.get_agency_references_integration.id,
    aws_api_gateway_method.post_agency_references.id,
    aws_api_gateway_integration.post_agency_references_integration.id,
    aws_api_gateway_model.feedback_model.id,
    aws_api_gateway_resource.feedback_resource.id,
    aws_api_gateway_method.post_feedback.id,
    aws_api_gateway_integration.post_feedback_integration.id
    ]))
  }
  lifecycle { create_before_destroy = true }
}

# Stage for the deployment
resource "aws_api_gateway_stage" "rest_api_stage" {
  deployment_id = aws_api_gateway_deployment.rest_api_deployment.id
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  stage_name  = var.environment
}

# Permissions for the Lambdas
resource "aws_lambda_permission" "allow_rest_api" {
  statement_id = "AllowAPIGatewayInvoke"
  action    = "lambda:InvokeFunction"
  function_name = module.lambda["batch-processing-validation-pre-process"].lambda_name
  principal  = "apigateway.amazonaws.com"
  source_arn  = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_content_api_handler" {
  statement_id = "AllowAPIGatewayInvokeContentHandler"
  action    = "lambda:InvokeFunction"
  function_name = module.lambda["batch-processing-content-api-handler"].lambda_name
  principal  = "apigateway.amazonaws.com"
  source_arn  = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_feedback_lambda" {
  statement_id  = "AllowAPIGatewayInvokeFeedback"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda["feedback"].lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*"
}