variable "table_name" { type = string }
variable "hash_key" { 
    description = "The name of the partition key attribute." 
    type = string 
}
variable "billing_mode" { default = "PAY_PER_REQUEST" }

variable "attributes" {
  description = "A list of all attributes for the table and its indexes."
  type = list(object({
    name = string
    type = string
  }))
}

variable "global_secondary_indexes" {
  description = "A list of GSI configurations."
  type = list(object({
    name            = string
    hash_key        = string
    range_key       = optional(string) 
    projection_type = string
  }))
  default = []
}