variable "name_ecr" {
  description = "Name of the ECR repository"
  type        = string
}

variable "ecr_tags" {
  description = "Tags to apply to the ECR repository"
  type        = map(string)
  default     = {
    Environment = "Development"
    Terraform   = "true"
  }
}

# Variable to control image tag mutability
variable "enable_immutable_tags" {
  description = "Set to true to make image tags immutable (cannot be overwritten), false for mutable tags"
  type        = bool
  default     = false # Default to mutable tags
}
