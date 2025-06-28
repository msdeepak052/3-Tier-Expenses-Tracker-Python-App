vpc_cidr     = "10.0.0.0/16"
vpc_name     = "expense-tracker-deepak-vpc"
cluster_name = "expense-tracker-deepak-cluster"
subnets = [
  {
    name = "subnet-public-1"
    cidr = "10.0.1.0/24"
    az   = "ap-south-1a"
  },
  {
    name = "subnet-public-2"
    cidr = "10.0.2.0/24"
    az   = "ap-south-1b"
  },
  {
    name = "subnet-private-1"
    cidr = "10.0.101.0/24"
    az   = "ap-south-1a"
  },
  {
    name = "subnet-private-2"
    cidr = "10.0.102.0/24"
    az   = "ap-south-1b"
  }
]

security_groups = {
  "self-hosted-runner" = {
    description = "Security group for self-hosted-runner server"
    ingress = [
      { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
      { from_port = 8080, to_port = 8080, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
    ]
    egress = [
      { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
    ]
  }

  "nexus" = {
    description = "Security group for Nexus server"
    ingress = [
      { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
      { from_port = 8081, to_port = 8081, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
    ]
    egress = [
      { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
    ]
  }

  "sonarqube" = {
    description = "Security group for SonarQube server"
    ingress = [
      { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
      { from_port = 9000, to_port = 9000, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
    ]
    egress = [
      { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
    ]
  }

  "rds" = {
    description = "Security group for RDS PostgreSQL database"
    ingress = [
      { from_port = 5432, to_port = 5432, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"] }
    ]
    egress = [
      { from_port = 5432, to_port = 5432, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
    ]
  }
}

pvt_destination_route_cidr = "0.0.0.0/0"

# RDS Configuration
rds_identifier             = "expense-db"
rds_instance_class         = "db.t3.micro"
rds_allocated_storage      = 15
rds_max_allocated_storage  = 20
rds_engine                 = "postgres"
rds_engine_version         = "15.7"
rds_username               = "deepakdbuser"
rds_name                   = "expense_db"
rds_parameter_group_family = "postgres15"

rds_skip_final_snapshot = true
rds_publicly_accessible = false
rds_multi_az            = false
rds_storage_encrypted   = false
rds_apply_immediately   = true

environment = "dev"
application = "expense-tracker"

