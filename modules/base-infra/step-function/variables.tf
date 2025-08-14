variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment name (e.g., dev, prod)"
  type        = string
}

variable "state_machine_name" {
  description = "The name of the state machine"
  type        = string
}

variable "definition" {
  description = "The Amazon States Language definition of the state machine"
  type        = string
  sensitive   = true
}

variable "state_machine_type" {
  description = "The type of the state machine (STANDARD or EXPRESS)."
  type        = string
  default     = "STANDARD"
}