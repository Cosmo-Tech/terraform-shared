locals {
  harbor_values = {
    POSTGRES_PASSWORD_SECRET_KEY       = "harbor_postgres_password"
    POSTGRES_ADMIN_PASSWORD_SECRET_KEY = "harbor_postgres_admin_password"
    HARBOR_ADMIN_PASSWORD              = "harbor_admin_password"
    SECRET                             = "harbor-config"

  }
}

resource "helm_release" "harbor" {
  name             = "harbor"
  repository       = var.harbor_helm_repo
  chart            = var.harbor_helm_chart
  version          = var.harbor_helm_chart_version
  namespace        = "harbor"
  create_namespace = true
  wait             = false
  wait_for_jobs    = false
  values = [
    templatefile("${path.root}/helm-templates/harbor/values.yaml", local.harbor_values)
  ]
  depends_on = [helm_release.postgresql, helm_release.redis, kubernetes_secret.harbor_config]
}

resource "helm_release" "postgresql" {
  name       = "harbor-postgresql"
  repository = var.postgres_helm_repo
  chart      = var.postgres_helm_chart
  version    = var.postgres_helm_chart_version
  namespace  = "harbor"

  values = [
    templatefile("${path.root}/helm-templates/harbor/values-postgresql.yaml", local.harbor_values)
  ]
  depends_on = [kubernetes_secret.harbor_config]
}

resource "helm_release" "redis" {
  name       = "redis"
  repository = var.redis_helm_repo
  chart      = var.redis_helm_chart
  version    = var.redis_helm_chart_version
  namespace  = "harbor"

  values = [
    templatefile("${path.root}/helm-templates/harbor/values-redis.yaml", local.harbor_values)
  ]
}