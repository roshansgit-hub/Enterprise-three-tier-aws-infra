############################################
# DB Tier - Multi-AZ RDS PostgreSQL, private subnets only
############################################

resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids
  tags       = var.tags
}

resource "random_password" "master" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.environment}/db/master-credentials"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
  })
}

resource "aws_kms_key" "rds" {
  description         = "${var.environment} RDS encryption key"
  enable_key_rotation = true
  tags                = var.tags
}

resource "aws_db_instance" "main" {
  identifier     = "${var.environment}-app-db"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  db_name  = var.db_name
  username = var.master_username
  password = random_password.master.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]

  multi_az                     = var.multi_az
  backup_retention_period       = var.backup_retention_days
  backup_window                 = "03:00-04:00"
  maintenance_window            = "mon:04:30-mon:05:30"
  deletion_protection           = var.deletion_protection
  skip_final_snapshot           = var.skip_final_snapshot
  final_snapshot_identifier     = var.skip_final_snapshot ? null : "${var.environment}-app-db-final-snapshot"
  auto_minor_version_upgrade    = true
  performance_insights_enabled  = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = var.tags
}
