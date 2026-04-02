# ── VPC ──────────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "VPC ID — used by destroy pre-cleanup to find orphaned ALBs"
  value       = module.vpc.vpc_id
}

# ── EKS ──────────────────────────────────────────────────────────────────────

output "cluster_name" {
  description = "EKS cluster name — run: aws eks update-kubeconfig --name <value>"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

# ── RDS ──────────────────────────────────────────────────────────────────────

output "rds_endpoint" {
  description = "Paste into values-eks.yaml judgeDb.host"
  value       = module.rds.db_endpoint
}

output "app_secret_name" {
  description = "Secrets Manager secret name — auto-written to values-eks.yaml by infra.yml"
  value       = module.rds.app_secret_name
}

output "app_secret_arn" {
  description = "Secrets Manager ARN for app credentials"
  value       = module.rds.app_secret_arn
}

# ── IAM ───────────────────────────────────────────────────────────────────────

# ── Post-apply instructions ───────────────────────────────────────────────────

output "next_steps" {
  value = <<-EOT
    === Everything is automated via GitHub Actions ===

    infra.yml handles:
      ✓ terraform apply (phases 1 + 2)
      ✓ values-eks.yaml updated with RDS endpoint + secret name
      ✓ ArgoCD Application applied

    cd.yml handles (on git tag):
      ✓ Build + push images to GHCR
      ✓ values-eks.yaml version bumped
      ✓ ArgoCD auto-syncs

    Manual steps (one-time bootstrap only):
      1. aws s3 mb s3://judge-engine-tfstate-ACCOUNT_ID
      2. aws dynamodb create-table --table-name judge-engine-tflock ...
      3. Set GitHub secret AWS_ROLE_ARN — get from: terraform -chdir=bootstrap output github_actions_role_arn

    After first infra apply:
      Get ArgoCD admin password:
        kubectl get secret argocd-initial-admin-secret -n argocd \
          -o jsonpath='{.data.password}' | base64 -d

      Get ALB URL (after ArgoCD syncs):
        kubectl get ingress -n judge-engine
  EOT
}
