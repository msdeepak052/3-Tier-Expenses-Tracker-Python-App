# Output the connection details
output "rds_connection_details" {
  value = {
    endpoint = aws_db_instance.expense_tracker_db.endpoint
    username = aws_db_instance.expense_tracker_db.username
    # password = sensitive(random_password.db_password.result)
    password = random_password.db_password.result
    database = aws_db_instance.expense_tracker_db.db_name
  }
  description = "RDS PostgreSQL connection details"
}

output "rds_endpoint" {
  value = aws_db_instance.expense_tracker_db.endpoint
}
