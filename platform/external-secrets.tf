# ============================================================================
# External Secrets Operator — Fargate Profile
# ============================================================================

resource "aws_eks_fargate_profile" "external_secrets" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "external-secrets"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = aws_subnet.private[*].id

  selector {
    namespace = "external-secrets"
  }

  tags = {
    Name = "${var.cluster_name}-external-secrets-fargate-profile"
  }
}

# ============================================================================
# External Secrets Operator — IAM Role (IRSA)
# ============================================================================

resource "aws_iam_role" "external_secrets" {
  name = "${var.cluster_name}-external-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.cluster.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_id}:aud" = "sts.amazonaws.com"
            "${local.oidc_provider_id}:sub" = "system:serviceaccount:external-secrets:external-secrets-sa"
          }
        }
      }
    ]
  })

  tags = {
    Name    = "${var.cluster_name}-external-secrets-role"
    Purpose = "External Secrets Operator IRSA"
  }
}

resource "aws_iam_policy" "external_secrets" {
  name        = "${var.cluster_name}-external-secrets-policy"
  description = "IAM policy for External Secrets Operator to read from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  role       = aws_iam_role.external_secrets.name
  policy_arn = aws_iam_policy.external_secrets.arn
}

# ============================================================================
# External Secrets Operator — Helm Release
# ============================================================================

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-secrets-sa"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_secrets.arn
  }

  # Fargate injects its own TLS cert (valid for the pod hostname, not the
  # service DNS name). Using port 9443 avoids the conflict so the
  # cert-controller's self-signed cert is used instead.
  set {
    name  = "webhook.port"
    value = "9443"
  }

  set {
    name  = "certController.webhook.port"
    value = "9443"
  }

  depends_on = [
    aws_eks_fargate_profile.external_secrets,
    aws_eks_addon.coredns,
    helm_release.aws_load_balancer_controller
  ]
}

# ============================================================================
# ClusterSecretStore — AWS Secrets Manager
# ============================================================================

resource "kubectl_manifest" "cluster_secret_store" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1"
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
                name      = "external-secrets-sa"
                namespace = "external-secrets"
              }
            }
          }
        }
      }
    }
  })

  depends_on = [helm_release.external_secrets]
}
