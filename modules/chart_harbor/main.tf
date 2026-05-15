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
    PERSISTENCE_POSTGRESQL_PVC         = var.pvc_postgresql
    PERSISTENCE_REGISTRY_PVC           = var.pvc_registry
    PERSISTENCE_JOBSERVICE_PVC         = var.pvc_jobservice
    IMAGE_REGISTRY                     = var.image_registry
    IMAGE_REGISTRY_AUTH_SECRET         = var.image_registry_auth_secret
  }
}


resource "helm_release" "harbor" {
  namespace  = var.namespace
  name       = var.chart_harbor_release
  repository = var.chart_harbor_repository
  chart      = var.chart_harbor_name
  version    = var.chart_harbor_tag

  create_namespace = true

  wait          = false
  wait_for_jobs = false

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
  namespace  = var.namespace
  name       = var.chart_postgresql_release
  repository = var.chart_postgresql_repository
  chart      = var.chart_postgresql_name
  version    = var.chart_postgresql_tag

  values = [
    templatefile("${path.module}/values-postgresql.yaml", local.chart_values)
  ]
  depends_on = [
    kubernetes_secret.harbor_config
  ]
}


resource "helm_release" "redis" {
  namespace  = var.namespace
  name       = var.chart_redis_release
  repository = var.chart_redis_repository
  chart      = var.chart_redis_name
  version    = var.chart_redis_tag

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
