# Production Environment Configuration

aws_region  = "eu-west-1"
environment = "prd"

# EKS Cluster
cluster_name       = "workshop-eks-prd"
kubernetes_version = "1.31"

# VPC Configuration
vpc_cidr             = "10.20.0.0/16"
availability_zones   = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24", "10.20.13.0/24"]

# High Availability (multiple NAT gateways for production)
single_nat_gateway = false
enable_nat_gateway = true

# Cluster Configuration
cluster_endpoint_private_access = true
cluster_endpoint_public_access  = true

# Logging (full logging with longer retention)
cluster_log_types          = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
cluster_log_retention_days = 30

# Fargate Namespaces
fargate_namespaces = ["kube-system", "default", "production", "workshop"]

# ECR Repositories
projects = []

# Aurora PostgreSQL (production: full protection, longer retention)
enable_aurora                   = true
aurora_instance_class           = "db.r6g.xlarge"
aurora_deletion_protection      = true
aurora_skip_final_snapshot      = false
aurora_backup_retention_period  = 14
aurora_backup_schedule          = "cron(0 2 * * ? *)"
aurora_backup_delete_after_days = 90
