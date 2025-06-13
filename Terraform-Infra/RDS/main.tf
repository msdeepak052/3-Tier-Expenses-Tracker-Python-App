provider "aws" {
  region = "us-west-2" # Change to your region
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "expense-tracker-rds-sg"
  description = "Allow inbound from EKS and local IP"
  vpc_id      = data.aws_vpc.eks_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # For testing only - restrict in production!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "expense-tracker-rds"
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "expense_tracker_db" {
  identifier             = "expense-tracker-db"
  instance_class         = "db.t3.micro" # Free tier eligible
  allocated_storage      = 20
  max_allocated_storage  = 50 # Enable storage autoscaling
  engine                 = "postgres"
  engine_version         = "14.5"
  username               = "expenseadmin"
  password               = random_password.db_password.result
  db_name                = "expensetracker"
  parameter_group_name   = aws_db_parameter_group.expense_tracker_pg.name
  skip_final_snapshot    = true # For testing - remove in production
  publicly_accessible    = true # For testing - set false in production
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  multi_az               = false # For testing - enable in production
  storage_encrypted      = false # For testing - enable in production
  apply_immediately      = true

  tags = {
    Environment = "test"
    Application = "expense-tracker"
  }
}

# Custom Parameter Group
resource "aws_db_parameter_group" "expense_tracker_pg" {
  name   = "expense-tracker-pg"
  family = "postgres14"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }
}

# Random password generator
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Get EKS VPC information
data "aws_vpc" "eks_vpc" {
  tags = {
    "Name" = "eks-vpc" # Update with your EKS VPC name
  }
}

# Output the connection details
output "rds_connection_details" {
  value = {
    endpoint = aws_db_instance.expense_tracker_db.endpoint
    username = aws_db_instance.expense_tracker_db.username
    password = sensitive(random_password.db_password.result)
    database = aws_db_instance.expense_tracker_db.db_name
  }
  description = "RDS PostgreSQL connection details"
}

# Kubernetes Secret for backend
resource "kubernetes_secret" "db_secret" {
  metadata {
    name = "backend-secrets"
    namespace = "default" # Update with your namespace
  }

  data = {
    DATABASE_URL = "postgresql://${aws_db_instance.expense_tracker_db.username}:${random_password.db_password.result}@${aws_db_instance.expense_tracker_db.endpoint}/${aws_db_instance.expense_tracker_db.db_name}"
  }

  depends_on = [aws_db_instance.expense_tracker_db]
}