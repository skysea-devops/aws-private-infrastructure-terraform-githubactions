resource "random_password" "rds_master" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name = "${var.project}/${var.env}/rds-credentials"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.rds_master_username
    password = random_password.rds_master.result
    engine   = "postgres"
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = aws_db_instance.this.db_name
  })
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.env}-rds-subnet-group"
  subnet_ids = [for s in aws_subnet.private : s.id]
  tags       = merge(local.tags, { Name = "${var.project}-${var.env}-rds-subnet-group" })
}

resource "aws_db_instance" "this" {
  identifier     = "${var.project}-${var.env}-postgres"
  engine         = "postgres"
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class

  allocated_storage       = var.rds_allocated_storage
  storage_type            = "gp3"
  storage_encrypted       = true
  backup_retention_period = var.rds_backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  db_name  = replace("${var.project}${var.env}", "-", "")
  username = var.rds_master_username
  password = random_password.rds_master.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.project}-${var.env}-final-snapshot"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = merge(local.tags, { Name = "${var.project}-${var.env}-postgres" })
}
