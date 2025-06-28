variable "vpc_id" {
  description = "VPC ID to associate with security groups"
  type        = string
}

variable "security_groups" {
  description = "Map of security group configurations"
  type = map(object({
    description = string
    ingress = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
    egress = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
  }))
}
