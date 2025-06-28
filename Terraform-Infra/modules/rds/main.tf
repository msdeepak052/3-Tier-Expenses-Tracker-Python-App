# Random password generator
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "expense_tracker_subnet_group" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.identifier}-subnet-group"
    Environment = var.environment
  }
}

# Store in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password_secret" {
  name        = "${var.identifier}-db-password"
  description = "Password for ${var.identifier} RDS instance"
}
# resource "aws_secretsmanager_secret_version" "db_password_version" {
#   secret_id     = aws_secretsmanager_secret.db_password_secret.id
#   secret_string = random_password.db_password.result

#   depends_on = [aws_db_instance.expense_tracker_db]
# }

resource "aws_secretsmanager_secret_version" "db_password_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_password_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    db_name  = var.db_name
  })
}




# RDS PostgreSQL Instance
resource "aws_db_instance" "expense_tracker_db" {
  identifier             = var.identifier
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  max_allocated_storage  = var.max_allocated_storage
  engine                 = var.engine
  engine_version         = var.engine_version
  username               = var.db_username
  password               = random_password.db_password.result
  db_name                = var.db_name
  db_subnet_group_name   = aws_db_subnet_group.expense_tracker_subnet_group.name
  parameter_group_name   = aws_db_parameter_group.expense_tracker_pg.name
  skip_final_snapshot    = var.skip_final_snapshot
  publicly_accessible    = var.publicly_accessible
  vpc_security_group_ids = [var.vpc_security_group_ids]
  multi_az               = var.multi_az
  storage_encrypted      = var.storage_encrypted
  apply_immediately      = var.apply_immediately

  tags = {
    Environment = var.environment
    Application = var.application
  }
}


# Custom Parameter Group

resource "aws_db_parameter_group" "expense_tracker_pg" {
  name        = "${var.identifier}-pg"
  family      = var.parameter_group_family
  description = "Custom parameter group for ${var.identifier}"
  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = {
    Name        = "${var.identifier}-pg"
    Environment = var.environment
  }
}
