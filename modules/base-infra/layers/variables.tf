variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The deployment environment"
  type        = string
}

variable "layers" {
  description = "A map of Lambda layers to create"
  type = map(object({
    compatible_runtimes = list(string)
  }))
}
