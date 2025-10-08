data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#############################################################
# 1. Service-Specific S3 Bucket
#############################################################
module "s3" {
  source        = "../../base-infra/s3"
  environment   = var.environment
  project_name  = var.project_name
  bucket_suffix = "batch-processing"
}

#############################################################
# 2. DynamoDB Tables
#############################################################
module "validation_table" {
  source     = "../../base-infra/dynamodb-table"
  table_name = "${var.project_name}-${var.environment}-batch-processing-validation"
  hash_key   = "user_date_stage"
  attributes = [
    { name = "user_date_stage", type = "S" }
  ]
}

module "validation_counter_table" {
  source     = "../../base-infra/dynamodb-table"
  table_name = "${var.project_name}-${var.environment}-batch-processing-validation-counter"
  hash_key   = "batch_id"
  attributes = [
    { name = "batch_id", type = "S" }
  ]
}

module "websocket_connections_table" {
  source     = "../../base-infra/dynamodb-table"
  table_name = "${var.project_name}-${var.environment}-batch-processing-websocket-connections"
  hash_key   = "connectionId"
  attributes = [
    { name = "connectionId", type = "S" },
    { name = "batch_id", type = "S" }
  ]
  global_secondary_indexes = [
    {
      name            = "batch_id-index"
      hash_key        = "batch_id"
      projection_type = "ALL"
    }
  ]
}

#############################################################
# 3. IAM Role for Lambdas
#############################################################
locals {
  service_policy_statements = [
    # CloudWatch Logs permissions (More secure than CloudWatchFullAccess)
    { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] },
    
    # VPC Lambda permissions (Matches your 'ec2_permission' policy)
    { Effect = "Allow", Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"], Resource = "*" },
    
    # S3 permissions (More secure than AmazonS3FullAccess)
    { Effect = "Allow", Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket", "s3:HeadObject"], Resource = [module.s3.bucket_arn, "${module.s3.bucket_arn}/*"] },
    
    # DynamoDB permissions (More secure than AmazonDynamoDBFullAccess)
    { Effect = "Allow", Action = ["dynamodb:Query", "dynamodb:Scan", "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem"], Resource = ["*"]
    },
    
    # SSM permissions (Matches your 'bulk_validation_ssm_permission' policy)
    { Effect = "Allow", Action = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"], Resource = ["*"] },
    
    # KMS permissions (Required for SecureString SSM parameters)
    { Effect = "Allow", Action = "kms:Decrypt", Resource = "*" },
    
    # SQS permissions (More secure than AmazonSQSFullAccess)
    { Effect = "Allow", Action = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:SendMessage"], Resource = "*" },
    
    # WebSocket API permissions (Matches your 'websocket_dynamodb' policy)
    { Effect = "Allow", Action = ["execute-api:ManageConnections"], Resource = ["${aws_apigatewayv2_api.websocket_api.execution_arn}/*"] },

    # Step Functions permissions (More secure than AWSStepFunctionsFullAccess)
    { Effect = "Allow", Action = ["states:StartExecution", "states:DescribeExecution", "states:StopExecution"], Resource = "*" },

    # SNS Full Access ---
    { Effect = "Allow", Action = "sns:*", Resource = "*" }

  ]

  zip_lambdas = {  
    for k, v in var.lambdas : k => v if lookup(v, "package_type", "Zip") == "Zip"
  }

  ecr_lambdas = {
    for k, v in var.lambdas : k => v if lookup(v, "package_type", "Zip") == "Image"
  }

  lambda_specific_env_vars = {
    "batch-processing-validation-aggregator" = {
      BATCH_S3_BUCKET        = module.s3.bucket_name
      CONNECTIONS_TABLE_NAME = module.websocket_connections_table.table_name
      COUNTER_TABLE_NAME     = module.validation_counter_table.table_name
      DB_NAME                = "postgres"
    },
    "batch-processing-validation-pre-process" = {
      DYNAMODB_TABLE_NAME = module.validation_counter_table.table_name,
      SQS_QUEUE_URL       = module.validation_sqs_trigger.main_queue_url
    },
    "batch-processing-validation-statemachine-fail" = {
      CONNECTIONS_TABLE_NAME = module.websocket_connections_table.table_name,
      COUNTER_TABLE_NAME     = module.validation_counter_table.table_name,
      DB_NAME                = "postgres"
    },
    "batch-processing-ws-connect" = {
      TABLE_NAME             = module.websocket_connections_table.table_name
    },
    "batch-processing-ws-disconnect" = {
      TABLE_NAME = module.websocket_connections_table.table_name
    },
    "batch-processing-content-child-sfn-rfp-text" = {
      BATCH_BUCKET = module.s3.bucket_name
    },
  }
}

module "batch_processing_lambda_role" {
  source              = "../../base-infra/iam-lambda"
  role_name           = "${var.project_name}-${var.environment}-batch-processing-role"
  project_name        = var.project_name
  environment         = var.environment
  policy_statements   = local.service_policy_statements
}

#############################################################
# 4. Lambda Functions (ZIP-BASED)
#############################################################
module "lambda" {
  for_each = local.zip_lambdas

  source        = "../../base-infra/lambda"
  function_name = "${var.project_name}-${var.environment}-${each.key}"

  runtime             = each.value.runtime
  timeout             = each.value.timeout
  memory_size         = each.value.memory_size
  layers              = [for layer_key in each.value.layers : var.available_layer_arns[layer_key]]
  environment_variables = merge(
    each.value.env_vars,
    { SSM_PREFIX = "${var.project_name}-${var.environment}" },
    lookup(local.lambda_specific_env_vars, each.key, {})
  )

  s3_bucket        = var.placeholder_s3_bucket
  s3_key           = var.placeholder_s3_key
  source_code_hash = var.placeholder_source_code_hash
  lambda_role_arn  = module.batch_processing_lambda_role.role_arn

  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [var.lambda_security_group_id]
}

#############################################################
# 5. ECR-based Lambda Functions 
#############################################################
resource "aws_ecr_repository" "ecr_repo" {
  for_each = local.ecr_lambdas
  name        = "${var.project_name}-${var.environment}-${each.key}"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "docker_image" "placeholder" {
  for_each = local.ecr_lambdas

  name = "${aws_ecr_repository.ecr_repo[each.key].repository_url}:placeholder"
  build {
    context = "${path.module}/placeholder-image"
    platform = "linux/amd64"
  }
}

resource "docker_registry_image" "placeholder" {
  for_each = local.ecr_lambdas
  name  = docker_image.placeholder[each.key].name
}

resource "aws_lambda_function" "lambda_ecr" {
  for_each = local.ecr_lambdas

  function_name = "${var.project_name}-${var.environment}-${each.key}"
  role     = module.batch_processing_lambda_role.role_arn
  package_type = "Image"
  image_uri  = docker_registry_image.placeholder[each.key].name

  timeout  = each.value.timeout
  memory_size = each.value.memory_size
  environment {
    variables = merge(
    each.value.env_vars,
    { SSM_PREFIX = "${var.project_name}-${var.environment}" },
        lookup(local.lambda_specific_env_vars, each.key, {})
    )
 }
 vpc_config {
    subnet_ids    = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
 }

  lifecycle {
    ignore_changes = [image_uri]
  }
}

#############################################################
# 5 & 6 Api Gateway Rest And Websocket (in separate files)
#############################################################


#############################################################
# 7. SQS Queues and Lambda Trigger Validation
#############################################################
module "validation_sqs_trigger" {
  source                     = "../../base-infra/sqs-lambda-trigger"
  project_name               = var.project_name
  environment                = var.environment
  queue_name                 = "batch-processing-validation"
  lambda_trigger_arn         = module.lambda["batch-processing-validation-state-machine"].lambda_arn
  visibility_timeout_seconds = 11
  max_message_size           = 262144
  max_receive_count          = 5
  aws_account_id             = data.aws_caller_identity.current.account_id
}

#############################################################
# 8. FIFO SQS Queue for Content Processing
#############################################################
resource "aws_sqs_queue" "content_fifo_queue" {
  name = "${var.project_name}-${var.environment}-batch-processing-content-queue.fifo"

  # These two arguments enable FIFO functionality
  fifo_queue                 = true
  content_based_deduplication = true
  max_message_size           = 262144
  visibility_timeout_seconds = 121
}

# The Lambda Trigger for the FIFO queue
resource "aws_lambda_event_source_mapping" "content_fifo_trigger" {
  event_source_arn = aws_sqs_queue.content_fifo_queue.arn
  function_name    = module.lambda["batch-processing-content-orchestrator"].lambda_arn
}

#############################################################
# 9. EventBridge Rule for Validation Success
#############################################################
module "on_validation_success_rule" {
  source      = "../../base-infra/eventbridge"
  environment = var.environment
  project_name = var.project_name
  suffix      = "batch-processing-OnValidationSuccess"

  lambda_arn_to_trigger = module.lambda["batch-processing-validation-aggregator"].lambda_arn
  event_pattern = jsonencode({
    "source" : ["aws.states"],
    "detail-type" : ["Step Functions Execution Status Change"],
    "detail" : {
      "status" : ["SUCCEEDED"],
      "stateMachineArn" : [var.validation_state_machine_arn]
    }
  })
}

module "on_validation_failure_rule" {
  source      = "../../base-infra/eventbridge"
  environment = var.environment
  project_name = var.project_name
  suffix      = "batch-processing-OnValidationFailure"

  # Trigger the failure handler lambda
  lambda_arn_to_trigger = module.lambda["batch-processing-validation-statemachine-fail"].lambda_arn
  
  event_pattern = jsonencode({
    "source" : ["aws.states"],
    "detail-type" : ["Step Functions Execution Status Change"],
    "detail" : {
      "status" : ["FAILED", "TIMED_OUT", "ABORTED"],
      "stateMachineArn" : [var.validation_state_machine_arn]
    }
  })
}

#############################################################
# 10. Step Functions
#############################################################

module "content_child_sfn" {
  source = "../../base-infra/step-function"

  project_name       = var.project_name
  environment        = var.environment
  state_machine_name = "batch-processing-content-child-sfn"
  definition = templatefile("${path.module}/state-machine-2.tftpl", {
    # Lambdas from the 'batch-processing' service
    lambda_child_sfn_rfp_text_arn = module.lambda["batch-processing-content-child-sfn-rfp-text"].lambda_arn
    lambda_child_sfn_handle_failure_arn = module.lambda["batch-processing-content-child-sfn-handle-failure"].lambda_arn 
    lambda_update_status_arn            = module.lambda["batch-processing-content-child-sfn-update-status"].lambda_arn
    
    # Lambdas from the 'drafting' service
    lambda_system_summary_arn   = var.drafting_lambda_arns["drafting-system-summary"]
    lambda_table_of_content_arn = var.drafting_lambda_arns["drafting-table-of-content"]
    lambda_company_data_arn     = var.drafting_lambda_arns["drafting-company-data"]
    lambda_user_summary_arn     = var.drafting_lambda_arns["drafting-summary"] 
    lambda_cost_summary_arn     = var.drafting_lambda_arns["drafting-rfp-cost-summary"]
    lambda_user_preference_arn  = var.drafting_lambda_arns["drafting-user-preference"]
    lambda_section_content_arn = var.drafting_lambda_arns["drafting-section-content-batch"]
    lambda_toc_extract_arn          = var.drafting_lambda_arns["drafting-toc-extract"]

    # Lambdas from the 'deep-research' service
    lambda_deep_research_topic_arn     = var.deep_research_lambda_arns["deep-research-query"]
    lambda_deep_research_prompt_arn    = var.deep_research_lambda_arns["deep-research-prompt"] 
    lambda_deep_research_execution_arn = var.deep_research_lambda_arns["deep-research"]  
    lambda_deep_research_pulling_arn   = var.deep_research_lambda_arns["deep-research-polling"] 
  })
  state_machine_type = "STANDARD"
}