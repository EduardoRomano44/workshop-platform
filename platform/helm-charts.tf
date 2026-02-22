# ============================================================================
# AWS Load Balancer Controller
# ============================================================================
/*
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.lb_controller.arn
    }
  }

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_fargate_profile.kube_system
  ]
}
*/

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.11.0"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.main.name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller-sa"
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = aws_vpc.main.id
  }

  # On Fargate, controller pods take longer to start. Setting failurePolicy
  # to Ignore prevents the webhook from blocking Service creation while the
  # controller is coming up.
  set {
    name  = "serviceMutatorWebhookConfig.failurePolicy"
    value = "Ignore"
  }

  depends_on = [
    #kubernetes_service_account.aws_load_balancer_controller,
    aws_eks_addon.coredns
  ]
}
