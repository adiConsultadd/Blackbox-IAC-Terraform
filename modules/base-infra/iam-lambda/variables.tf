variable "role_name"{ 
    type = string 
}
variable "project_name"{ 
    type = string
}
variable "environment"{
    type = string 
}
variable "policy_statements"{
  description = "List of IAM policy statement blocks to attach inline"
  type        = any
}