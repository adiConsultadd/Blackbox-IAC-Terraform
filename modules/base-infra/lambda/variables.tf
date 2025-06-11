variable "function_name" {
  description = "Fully‑qualified Lambda function name"
  type        = string
}

variable "source_dir" {
  description = "Directory containing Lambda source (unzipped)"
  type        = string
}

variable "lambda_role_arn" {
  description = "IAM role ARN for Lambda execution"
  type        = string
}

variable "runtime" { 
  type = string  
  default = "python3.9" 
}

variable "handler" { 
  type = string  
  default = "index.handler" 

}

variable "timeout" { 
  type = number  
  default = 30 
}

variable "memory_size" { 
  type = number  
  default = 128 

}
variable "environment_variables" {
  type        = map(string)
  default     = {}
  description = "Key/value pairs injected into the function"
}
