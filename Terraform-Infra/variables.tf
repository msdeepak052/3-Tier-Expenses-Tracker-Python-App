variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

# VPC Variables
# These variables are used to configure the VPC, including the CIDR block, name,

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "subnets" {
  type = list(object({
    name = string
    cidr = string
    az   = string
  }))
  description = "List of subnets to create"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}


variable "pvt_destination_route_cidr" {
  type        = string
  description = "pvt_route_cidr"

}

# Security Group Variables
# These variables are used to configure security groups for different components like self-hosted-runner, Nexus, Sonar

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

# # EKS Cluster Variables 
# These variables are used to configure the EKS cluster and worker nodes.
# They include the cluster name, Kubernetes version, desired number of nodes, instance type, etc

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string

}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "desired_nodes" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "max_nodes" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 2
}

variable "min_nodes" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "eks_instance_type" {
  description = "Instance type for EKS worker nodes"
  type        = string
  default     = "t2.medium"
}

variable "ec2_instance_type" {
  description = "Instance type for EC2 instances"
  type        = string
  default     = "t2.medium"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0e35ddab05955cf57" # Ubuntu Machine
}

variable "key_name" {
  description = "Name of the EC2 key pair"
  type        = string
  default     = "lappynewawss"
}
variable "name_ecr" {
  description = "Name of the ECR repository"
  type        = string
  default     = "app/expense-tracker-deepak-webapp"
}
variable "enable_immutable_tags" {
  description = "Enable immutable tags for ECR repository"
  type        = bool
  default     = false
}

variable "ecr_tags" {
  description = "Tags for the ECR repository"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "expense-tracker-deepak-webapp-ecr"
  }
}

variable "eks_admin_instance_profile_name" {
  description = "Name of the EKS admin instance profile"
  type        = string
  default     = "eks-admin-instance-profile"
}
variable "rds_identifier" {}
variable "rds_instance_class" {}
variable "rds_allocated_storage" {}
variable "rds_max_allocated_storage" {}
variable "rds_engine" {}
variable "rds_engine_version" {}
variable "rds_username" {}
variable "rds_name" {}
variable "rds_parameter_group_family" {}
variable "rds_skip_final_snapshot" {
  type = bool
}
variable "rds_publicly_accessible" {
  type = bool
}
variable "rds_multi_az" {
  type = bool
}
variable "rds_storage_encrypted" {
  type = bool
}
variable "rds_apply_immediately" {
  type = bool
}
variable "environment" {}
variable "application" {}
