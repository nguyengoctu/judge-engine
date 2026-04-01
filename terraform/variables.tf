variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name — used in resource naming and tags"
  type        = string
  default     = "judge-engine"
}

variable "environment" {
  description = "Deployment environment (prod / staging)"
  type        = string
  default     = "prod"
}

# ── VPC ─────────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (ALB, NAT gateway)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (EKS nodes, RDS)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

# ── EKS ─────────────────────────────────────────────────────────────────────

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "judge-engine"
}

variable "eks_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_min" {
  type    = number
  default = 2
}

variable "node_max" {
  type    = number
  default = 10
}

variable "node_desired" {
  type    = number
  default = 2
}

# ── RDS ─────────────────────────────────────────────────────────────────────

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "judgedb"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "postgres"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS (costs 2×)"
  type        = bool
  default     = false
}

