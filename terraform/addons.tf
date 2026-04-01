# ─────────────────────────────────────────────────────────────────────────────
# Kubernetes add-ons installed via Helm + kubernetes_manifest.
#
# infra.yml applies these automatically in two phases:
#   Phase 1: terraform apply -target=module.vpc -target=module.eks ...
#   Phase 2: terraform apply   ← this file
# ─────────────────────────────────────────────────────────────────────────────

# ── gp3 StorageClass ──────────────────────────────────────────────────────────
# Default StorageClass for PVCs (RabbitMQ, Redis).
# Replaces the legacy gp2 that EKS ships with.

resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }

  depends_on = [module.eks]
}

# Patch the old gp2 to remove its default annotation
resource "kubernetes_annotations" "gp2_not_default" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  metadata { name = "gp2" }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "false"
  }
  force      = true
  depends_on = [module.eks]
}

# ── AWS Load Balancer Controller ──────────────────────────────────────────────

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam.alb_controller_role_arn
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  depends_on = [module.eks, module.iam, kubernetes_storage_class_v1.gp3]
}

# ── ArgoCD ────────────────────────────────────────────────────────────────────

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  version          = "7.3.11"
  create_namespace = true

  values = [
    yamlencode({
      server = {
        service = {
          # Use ClusterIP; access via kubectl port-forward or add an Ingress
          type = "ClusterIP"
        }
      }
      configs = {
        params = {
          # Disable TLS termination inside ArgoCD — handled by ALB/Ingress
          "server.insecure" = true
        }
      }
    })
  ]

  depends_on = [module.eks, helm_release.aws_load_balancer_controller]
}

# ── KEDA ──────────────────────────────────────────────────────────────────────

resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  namespace        = "keda"
  version          = "2.14.2"
  create_namespace = true

  depends_on = [module.eks]
}

# ── Cluster Autoscaler ────────────────────────────────────────────────────────

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.37.0"

  set {
    name  = "autoDiscovery.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam.cluster_autoscaler_role_arn
  }

  depends_on = [module.eks, module.iam]
}

# ── External Secrets Operator ─────────────────────────────────────────────────
# Watches ExternalSecret CRs → pulls from Secrets Manager → creates K8s Secrets.
# No manual kubectl create secret needed ever again.

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  version          = "0.9.19"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [module.eks]
}

# ServiceAccount with IRSA so ESO can read from Secrets Manager
resource "kubernetes_service_account_v1" "eso" {
  metadata {
    name      = "external-secrets-sa"
    namespace = "external-secrets"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam.eso_role_arn
    }
  }

  depends_on = [helm_release.external_secrets]
}

# ClusterSecretStore — single store for the whole cluster.
# Using null_resource because kubernetes_manifest validates CRDs at plan time,
# but ESO CRDs don't exist until the helm_release above is applied.
resource "null_resource" "cluster_secret_store" {
  triggers = {
    manifest = sha256(jsonencode({
      apiVersion = "external-secrets.io/v1beta1"
      kind       = "ClusterSecretStore"
      metadata = {
        name = "aws-secrets-manager"
      }
      spec = {
        provider = {
          aws = {
            service = "SecretsManager"
            region  = var.aws_region
            auth = {
              jwt = {
                serviceAccountRef = {
                  name      = kubernetes_service_account_v1.eso.metadata[0].name
                  namespace = "external-secrets"
                }
              }
            }
          }
        }
      }
    }))
  }

  provisioner "local-exec" {
    command = <<-EOT
      cat <<'EOF' | kubectl apply -f -
      apiVersion: external-secrets.io/v1beta1
      kind: ClusterSecretStore
      metadata:
        name: aws-secrets-manager
      spec:
        provider:
          aws:
            service: SecretsManager
            region: ${var.aws_region}
            auth:
              jwt:
                serviceAccountRef:
                  name: ${kubernetes_service_account_v1.eso.metadata[0].name}
                  namespace: external-secrets
      EOF
    EOT
  }

  depends_on = [helm_release.external_secrets, kubernetes_service_account_v1.eso]
}

