data "aws_caller_identity" "current" {}

locals {
  name = "${var.project}-${var.environment}"
}

# ── IAM: Cluster Role ─────────────────────────────────────────────────────────

resource "aws_iam_role" "cluster" {
  name = "${local.name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ── IAM: Node Group Role ──────────────────────────────────────────────────────

resource "aws_iam_role" "node" {
  name = "${local.name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_ssm" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ── Security Group: Cluster ───────────────────────────────────────────────────

resource "aws_security_group" "cluster" {
  name        = "${local.name}-eks-cluster-sg"
  description = "EKS cluster control plane security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-eks-cluster-sg" }
}

# ── Security Group: Nodes ─────────────────────────────────────────────────────

resource "aws_security_group" "nodes" {
  name        = "${local.name}-eks-nodes-sg"
  description = "EKS worker nodes security group"
  vpc_id      = var.vpc_id

  # Nodes can talk to each other
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # Control plane → nodes (webhooks, metrics)
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
  }

  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-eks-nodes-sg" }
}

# ── EKS Cluster ───────────────────────────────────────────────────────────────

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.eks_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
  ]
}

# ── OIDC Provider (for IRSA) ──────────────────────────────────────────────────

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# ── EKS Managed Node Group ────────────────────────────────────────────────────

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.name}-main"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = [var.node_instance_type]

  scaling_config {
    min_size     = var.node_min
    max_size     = var.node_max
    desired_size = var.node_desired
  }

  update_config {
    max_unavailable = 1
  }

  # Worker needs privileged containers for Docker-in-Docker
  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# Launch template — no special config needed, but kept for future customisation
resource "aws_launch_template" "node" {
  name_prefix            = "${local.name}-node-"
  update_default_version = true

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${local.name}-eks-node" }
  }
}

# ── EKS Add-ons ───────────────────────────────────────────────────────────────

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_update = "OVERWRITE"
}

# EBS CSI driver — required for PersistentVolumeClaims (RabbitMQ, Redis)
resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = aws_iam_role.ebs_csi.arn
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.main]
}

# ── IRSA: EBS CSI Driver ──────────────────────────────────────────────────────

data "aws_iam_policy_document" "ebs_csi_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "${local.name}-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_trust.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ── gp3 StorageClass (default) ────────────────────────────────────────────────
# Sets gp3 as the default StorageClass so PVCs (RabbitMQ, Redis) use it.
# Applied via null_resource + kubectl after cluster is ready.
# See outputs for the kubectl command.
