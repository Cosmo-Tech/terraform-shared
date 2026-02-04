locals {
  chart_values = {
    NAMESPACE                          = var.namespace
    CLUSTER_DOMAIN                     = var.cluster_domain
    HARBOR_ADMIN_PASSWORD              = "harbor_admin_password"
    POSTGRES_ADMIN_PASSWORD_SECRET_KEY = "harbor_postgres_admin_password"
    POSTGRES_PASSWORD_SECRET_KEY       = "harbor_postgres_password"
    SECRET                             = "harbor-config"
    PERSISTENCE_STORAGE_CLASS          = var.pvc_storage_class
    PERSISTENCE_REDIS_PVC              = var.pvc_redis
    # PERSISTENCE_REDIS_SIZE       = var.size_redis
    PERSISTENCE_POSTGRESQL_PVC = var.pvc_postgresql
    # PERSISTENCE_POSTGRESQL_SIZE  = var.size_postgresql
    PERSISTENCE_REGISTRY_PVC = var.pvc_registry
    # PERSISTENCE_REGISTRY_SIZE    = var.size_registry
    PERSISTENCE_JOBSERVICE_PVC = var.pvc_jobservice
    # PERSISTENCE_JOBSERVICE_SIZE  = var.size_jobservice
    PERSISTENCE_CHARTMUSEUM_PVC = var.pvc_chartmuseum
    # PERSISTENCE_CHARTMUSEUM_SIZE = var.size_chartmuseum
    PERSISTENCE_TRIVY_PVC = var.pvc_trivy
    # PERSISTENCE_TRIVY_SIZE       = var.size_trivy
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
    templatefile("${path.module}/values-harbor.yaml", local.chart_values)
  ]
  depends_on = [
    helm_release.postgresql,
    helm_release.redis,
    kubernetes_secret.harbor_config
  ]
}


resource "helm_release" "postgresql" {
  name       = "harbor-postgresql"
  repository = var.postgres_helm_repo
  chart      = var.postgres_helm_chart
  version    = var.postgres_helm_chart_version
  namespace  = "harbor"

  values = [
    templatefile("${path.module}/values-postgresql.yaml", local.chart_values)
  ]
  depends_on = [
    kubernetes_secret.harbor_config
  ]
}


resource "helm_release" "redis" {
  name       = "redis"
  repository = var.redis_helm_repo
  chart      = var.redis_helm_chart
  version    = var.redis_helm_chart_version
  namespace  = "harbor"

  values = [
    templatefile("${path.module}/values-redis.yaml", local.chart_values)
  ]
}


resource "random_password" "harbor_postgres_password" {
  length  = 30
  special = false
}


resource "random_password" "harbor_postgres_admin_password" {
  length  = 30
  special = false
}


resource "random_password" "harbor_admin_password" {
  length  = 30
  special = false
}


# -----------------------------
# Kubernetes Secret for harbor Config
# -----------------------------
resource "kubernetes_secret" "harbor_config" {
  metadata {
    name      = "harbor-config"
    namespace = "harbor"
    labels = {
      "app" = "harbor"
    }
  }

  data = {
    harbor_admin_password          = var.harbor_admin_password != "" ? var.harbor_admin_password : random_password.harbor_admin_password.result
    harbor_postgres_user           = var.harbor_postgres_user
    harbor_postgres_password       = var.harbor_postgres_password != "" ? var.harbor_postgres_password : random_password.harbor_postgres_password.result
    harbor_postgres_admin_password = var.harbor_postgres_admin_password != "" ? var.harbor_postgres_admin_password : random_password.harbor_postgres_admin_password.result
  }

  type = "Opaque"
}
