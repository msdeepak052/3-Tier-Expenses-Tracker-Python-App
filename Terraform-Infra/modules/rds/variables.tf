variable "identifier" {
  description = "The identifier for the RDS instance"
  type        = string
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for DB subnet group"
}

variable "allocated_storage" {
  description = "The allocated storage in GBs"
  type        = number
}

variable "max_allocated_storage" {
  description = "The upper limit for storage autoscaling"
  type        = number
}

variable "engine" {
  description = "The database engine to use"
  type        = string
}

variable "parameter_group_family" { 
  description = "The family of the DB parameter group"
  type        = string
}

variable "engine_version" {
  description = "The version of the database engine"
  type        = string
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
}

variable "db_name" {
  description = "Name of the initial database to create"
  type        = string
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot on destroy"
  type        = bool
}

variable "publicly_accessible" {
  description = "Whether the DB instance is publicly accessible"
  type        = bool
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
}

variable "storage_encrypted" {
  description = "Specifies whether the DB storage is encrypted"
  type        = bool
}

variable "apply_immediately" {
  description = "Whether to apply changes immediately"
  type        = bool
}

variable "environment" {
  description = "Environment tag"
  type        = string
}

variable "application" {
  description = "Application tag"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "Security Group ID to attach to the RDS instance"
  type        = string
}

