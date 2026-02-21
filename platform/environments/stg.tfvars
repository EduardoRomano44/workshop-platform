# Staging Environment Configuration

aws_region  = "eu-west-1"
environment = "stg"

# EKS Cluster
cluster_name       = "workshop-eks-stg"
kubernetes_version = "1.31"

# VPC Configuration
vpc_cidr             = "10.10.0.0/16"
availability_zones   = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
private_subnet_cidrs = ["10.10.11.0/24", "10.10.12.0/24", "10.10.13.0/24"]

# Cost Optimization (single NAT gateway for staging)
single_nat_gateway = true
enable_nat_gateway = true

# Cluster Configuration
cluster_endpoint_private_access = true
cluster_endpoint_public_access  = true

# Logging (moderate retention for staging)
cluster_log_types          = ["api", "audit", "authenticator", "controllerManager"]
cluster_log_retention_days = 7

# Fargate Namespaces
fargate_namespaces = ["kube-system", "default", "staging", "workshop"]

# ECR Repositories
projects = []

# Aurora PostgreSQL (staging: production-like with moderate retention)
enable_aurora                   = true
aurora_instance_class           = "db.r6g.large"
aurora_deletion_protection      = true
aurora_skip_final_snapshot      = false
aurora_backup_retention_period  = 7
aurora_backup_schedule          = "cron(0 2 * * ? *)"
aurora_backup_delete_after_days = 35
