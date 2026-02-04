locals {
  redis_admin_password      = var.redis_admin_password != "" ? var.redis_admin_password : (length(random_password.redis_admin_password) > 0 ? random_password.redis_admin_password[0].result : "")
  prometheus_admin_password = var.prometheus_admin_password != "" ? var.prometheus_admin_password : (length(random_password.prometheus_admin_password) > 0 ? random_password.prometheus_admin_password[0].result : "")

  chart_values = {
    COSMOTECH_CLUSTER_DOMAIN    = var.cluster_domain
    NAMESPACE                   = var.namespace
    PERSISTENCE_STORAGE_CLASS   = var.pvc_storage_class
    PERSISTENCE_SIZE_GRAFANA    = var.size_grafana
    PERSISTENCE_PVC_GRAFANA     = var.pvc_grafana
    PERSISTENCE_SIZE_PROMETHEUS = var.size_prometheus
    PERSISTENCE_PVC_PROMETHEUS  = var.pvc_prometheus
    PROMETHEUS_ADMIN_PASSWORD   = local.prometheus_admin_password
    REDIS_ADMIN_PASSWORD        = local.redis_admin_password
  }
}


resource "helm_release" "prometheus_stack" {
  name             = var.helm_release_name
  repository       = var.helm_repo_url
  chart            = var.helm_chart_name
  version          = var.helm_chart_version
  namespace        = var.namespace
  create_namespace = false

  timeout      = 600
  reuse_values = true

  values = [
    templatefile("${path.module}/values.yaml", local.chart_values)
  ]
}


# Random passwords (only generated if not provided)
resource "random_password" "redis_admin_password" {
  count   = var.redis_admin_password == "" ? 1 : 0
  length  = 30
  special = false
}


resource "random_password" "prometheus_admin_password" {
  count   = var.prometheus_admin_password == "" ? 1 : 0
  length  = 30
  special = false
}


# Secret for Redis datasource
resource "kubernetes_secret" "prom_redis_datasource" {
  metadata {
    name      = "cosmotech-prom-redis-datasource"
    namespace = var.namespace
  }

  data = {
    password = local.redis_admin_password
  }

  type = "Opaque"
}