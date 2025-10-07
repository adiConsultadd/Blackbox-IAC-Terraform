variable "project_name" { type = string }
variable "environment" { type = string }
variable "queue_name" { 
    description = "A base name for the queue, e.g., 'validation-processing'" 
    type = string 
}
variable "lambda_trigger_arn" { 
    description = "The ARN of the Lambda function to trigger" 
    type = string 
}

variable "visibility_timeout_seconds" {
  description = "The visibility timeout for the main queue."
  type        = number
  default     = 30
}
variable "max_message_size" {
  description = "The maximum message size in bytes."
  type        = number
  default     = 262144
}
variable "max_receive_count" {
  description = "The number of times a message is delivered before being sent to the DLQ."
  type        = number
  default     = 5
}