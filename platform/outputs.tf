# ============================================================================
# VPC Outputs
# ============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

# ============================================================================
# EKS Cluster Outputs
# ============================================================================

output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "Platform version of the EKS cluster"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = aws_eks_cluster.main.status
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

# ============================================================================
# OIDC Provider Outputs
# ============================================================================

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

# ============================================================================
# IAM Role Outputs
# ============================================================================

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = aws_iam_role.cluster.name
}

output "fargate_pod_execution_role_arn" {
  description = "IAM role ARN for Fargate pod execution"
  value       = aws_iam_role.fargate.arn
}

output "fargate_pod_execution_role_name" {
  description = "IAM role name for Fargate pod execution"
  value       = aws_iam_role.fargate.name
}

output "lb_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller IRSA"
  value       = aws_iam_role.lb_controller.arn
}

output "lb_controller_role_name" {
  description = "IAM role name for AWS Load Balancer Controller"
  value       = aws_iam_role.lb_controller.name
}

# ============================================================================
# Fargate Profile Outputs
# ============================================================================

output "fargate_profile_ids" {
  description = "Map of Fargate profile names to IDs"
  value = merge(
    {
      "kube-system" = aws_eks_fargate_profile.kube_system.id
      "default"     = aws_eks_fargate_profile.default.id
    },
    { for k, v in aws_eks_fargate_profile.additional : k => v.id }
  )
}

output "fargate_profile_arns" {
  description = "Map of Fargate profile names to ARNs"
  value = merge(
    {
      "kube-system" = aws_eks_fargate_profile.kube_system.arn
      "default"     = aws_eks_fargate_profile.default.arn
    },
    { for k, v in aws_eks_fargate_profile.additional : k => v.arn }
  )
}

# ============================================================================
# Configuration Helper Outputs
# ============================================================================

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "lb_controller_service_account_annotation" {
  description = "Annotation to add to AWS Load Balancer Controller service account for IRSA"
  value       = "eks.amazonaws.com/role-arn: ${aws_iam_role.lb_controller.arn}"
}

output "lb_controller_helm_install_command" {
  description = "Helm command to install AWS Load Balancer Controller with IRSA"
  value       = <<-EOT
    helm repo add eks https://aws.github.io/eks-charts
    helm repo update
    helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
      -n kube-system \
      --set clusterName=${aws_eks_cluster.main.name} \
      --set serviceAccount.create=true \
      --set serviceAccount.name=aws-load-balancer-controller \
      --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${aws_iam_role.lb_controller.arn}
  EOT
}

# ============================================================================
# Region and Account Outputs
# ============================================================================

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

# ============================================================================
# ECR Outputs
# ============================================================================

output "ecr_repository_urls" {
  description = "Map of project names to ECR repository URLs"
  value       = length(module.ecr) > 0 ? module.ecr[0].repository_urls : {}
}

output "ecr_repository_arns" {
  description = "Map of project names to ECR repository ARNs"
  value       = length(module.ecr) > 0 ? module.ecr[0].repository_arns : {}
}

# ============================================================================
# CI/CD User Outputs
# ============================================================================

output "ci_user_arns" {
  description = "Map of project names to CI user ARNs"
  value       = { for name, user in aws_iam_user.ci : name => user.arn }
}

output "ci_user_access_key_ids" {
  description = "Map of project names to CI user access key IDs"
  value       = { for name, key in aws_iam_access_key.ci : name => key.id }
}

output "ci_user_secret_access_keys" {
  description = "Map of project names to CI user secret access keys"
  value       = { for name, key in aws_iam_access_key.ci : name => key.secret }
  sensitive   = true
}
