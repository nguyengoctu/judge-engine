output "alb_controller_role_arn" {
  value = aws_iam_role.alb_controller.arn
}

output "cluster_autoscaler_role_arn" {
  value = aws_iam_role.cluster_autoscaler.arn
}

output "eso_role_arn" {
  value = aws_iam_role.eso.arn
}
