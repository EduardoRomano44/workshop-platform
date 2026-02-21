# Development Environment Configuration

aws_region  = "eu-west-1"
environment = "dev"

# EKS Cluster
cluster_name       = "workshop-eks-dev"
kubernetes_version = "1.31"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

# Cost Optimization (single NAT gateway for dev)
single_nat_gateway = true
enable_nat_gateway = true

# Cluster Configuration
cluster_endpoint_private_access = true
cluster_endpoint_public_access  = true

# Logging (shorter retention for dev)
cluster_log_types          = ["api", "audit", "authenticator"]
cluster_log_retention_days = 3

# Fargate Namespaces
fargate_namespaces = ["kube-system", "default", "development", "workshop"]

# ECR Repositories
projects = ["spring-petshop"]

# Aurora PostgreSQL (dev: relaxed protection for dev workflows)
enable_aurora                   = true
aurora_instance_class           = "db.r6g.large"
aurora_deletion_protection      = false
aurora_skip_final_snapshot      = true
aurora_backup_retention_period  = 3
aurora_backup_schedule          = "cron(0 2 * * ? *)"
aurora_backup_delete_after_days = 14
