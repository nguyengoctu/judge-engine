locals {
  name = "${var.project}-${var.environment}"
}

# ── Random passwords ──────────────────────────────────────────────────────────

resource "random_password" "db" {
  length  = 24
  special = true
  # URL-safe only — avoid :@%#/?= which break connection strings
  override_special = "!_-"
}

resource "random_password" "rabbitmq" {
  length  = 24
  special = false
}

# ── Secrets Manager — store ALL app credentials ───────────────────────────────
# Keys match exactly what services read as env vars.
# External Secrets Operator will sync these into a K8s Secret automatically.

resource "aws_secretsmanager_secret" "app" {
  name                    = "${local.name}/app/db_credentials"
  recovery_window_in_days = 0 # immediate deletion allowed in dev/staging
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({
    # PostgreSQL
    POSTGRES_USER     = var.db_username
    POSTGRES_PASSWORD = random_password.db.result
    # RabbitMQ (in-cluster, but credentials still managed here for consistency)
    RABBITMQ_USER = "judge"
    RABBITMQ_PASS = random_password.rabbitmq.result
  })

  # Re-generate if RDS is recreated (password changes)
  depends_on = [aws_db_instance.this]
}

# ── Security Group ────────────────────────────────────────────────────────────

resource "aws_security_group" "rds" {
  name        = "${local.name}-rds-sg"
  description = "Allow PostgreSQL access from EKS nodes"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
    description     = "PostgreSQL from EKS nodes"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-rds-sg" }
}

# ── Subnet Group ─────────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids
}

# ── Parameter Group ───────────────────────────────────────────────────────────

resource "aws_db_parameter_group" "this" {
  name   = "${local.name}-pg16"
  family = "postgres16"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000" # log slow queries > 1s
  }
}

# ── RDS Instance ──────────────────────────────────────────────────────────────

resource "aws_db_instance" "this" {
  identifier = "${local.name}-db"

  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.this.name

  multi_az                = var.db_multi_az
  publicly_accessible     = false
  deletion_protection     = false
  skip_final_snapshot     = true
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  tags = { Name = "${local.name}-db" }
}
