output "db_endpoint" {
  description = "RDS hostname — auto-written to values-eks.yaml by infra.yml"
  value       = aws_db_instance.this.address
}

output "db_port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = var.db_name
}

output "app_secret_arn" {
  description = "Secrets Manager ARN — used by External Secrets Operator"
  value       = aws_secretsmanager_secret.app.arn
}

output "app_secret_name" {
  description = "Secrets Manager secret name — used in ExternalSecret manifest"
  value       = aws_secretsmanager_secret.app.name
}
