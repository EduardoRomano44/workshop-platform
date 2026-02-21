# ============================================================================
# CI/CD IAM Users (one per project)
# ============================================================================

resource "aws_iam_user" "ci" {
  for_each = toset(var.projects)

  name = "${var.cluster_name}-${each.value}-ci-user"
  path = "/ci/"

  tags = {
    Name    = "${var.cluster_name}-${each.value}-ci-user"
    Purpose = "CI/CD for ${each.value}"
  }
}

# ============================================================================
# Access Keys
# ============================================================================

resource "aws_iam_access_key" "ci" {
  for_each = aws_iam_user.ci

  user = each.value.name
}

# ============================================================================
# IAM Policies
# ============================================================================

resource "aws_iam_policy" "ci" {
  for_each = toset(var.projects)

  name        = "${var.cluster_name}-${each.value}-ci-policy"
  description = "CI/CD policy for ${each.value} - ECR push and EKS deploy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuthToken"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
        Resource = module.ecr[0].repository_arns[each.value]
      },
      {
        Sid    = "EKSDescribe"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = aws_eks_cluster.main.arn
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-${each.value}-ci-policy"
  }
}

resource "aws_iam_user_policy_attachment" "ci" {
  for_each = aws_iam_user.ci

  user       = each.value.name
  policy_arn = aws_iam_policy.ci[each.key].arn
}

# ============================================================================
# EKS Access Entries (Kubernetes RBAC via EKS API)
# ============================================================================

resource "aws_eks_access_entry" "ci" {
  for_each = aws_iam_user.ci

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value.arn
  type          = "STANDARD"

  tags = {
    Name = "${var.cluster_name}-${each.key}-ci-access"
  }
}

resource "aws_eks_access_policy_association" "ci" {
  for_each = aws_iam_user.ci

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = [each.key]
  }

  depends_on = [aws_eks_access_entry.ci]
}

# ============================================================================
# Kubernetes Namespaces
# ============================================================================

resource "kubernetes_namespace" "ci" {
  for_each = toset(var.projects)

  metadata {
    name = each.value

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "project"                      = each.value
      "environment"                  = var.environment
    }
  }
}
