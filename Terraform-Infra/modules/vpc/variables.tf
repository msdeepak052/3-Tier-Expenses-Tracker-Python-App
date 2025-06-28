variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

# variable "public_subnet_cidrs" {
#   description = "List of public subnet CIDR blocks"
#   type        = list(string)
# }

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "subnets" {
  type = list(object({
    name = string
    cidr = string
    az   = string
  }))
  description = "List of subnets to create"
}


variable "pvt_destination_route_cidr" {
  type        = string
  description = "pvt_route_cidr"

}