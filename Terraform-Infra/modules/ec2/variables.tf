variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type for EC2 instances"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "key_name" {
  description = "Name of the EC2 key pair"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

# variable "eks_instance_profile_name" {
#   description = "IAM instance profile name for EKS admin EC2"
#   type        = string
# }

# variable "self-hosted-runner_ecr_access_name" {
#   description = "IAM instance profile name for self-hosted-runner ECR"
#   type        = string
# }

# variable "eks_cluster_name" {
#   type        = string
#   description = "EKS cluster name"
# }

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "security_group_id_self-hosted-runner" {
  description = "The ID of the security group for self-hosted-runner"
  type        = string
}

variable "security_group_id_nexus" {
  description = "The ID of the security group for Nexus"
  type        = string
}

variable "security_group_id_sonarqube" {
  description = "The ID of the security group for SonarQube"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}


variable "roles_tags" {
  description = "Tags to apply to the ECR repository"
  type        = map(string)
  default     = {
    Environment = "Development"
    Terraform   = "true"
  }
}