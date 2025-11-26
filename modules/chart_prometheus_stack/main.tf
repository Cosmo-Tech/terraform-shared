locals {
  redis_admin_password = var.redis_admin_password != "" ? var.redis_admin_password : (length(random_password.redis_admin_password) > 0 ? random_password.redis_admin_password[0].result : "")
  prom_admin_password  = var.prom_admin_password != "" ? var.prom_admin_password : (length(random_password.prom_admin_password) > 0 ? random_password.prom_admin_password[0].result : "")

  chart_values = {
    COSMOTECH_cluster_domain      = var.cluster_domain
    TLS_SECRET_NAME               = var.tls_secret_name
    REDIS_HOST                    = "cosmotechredis-${var.redis_host_namespace}-master.${var.redis_host_namespace}.svc.cluster.local"
    REDIS_PORT                    = var.redis_port
    REDIS_ADMIN_PASSWORD          = local.redis_admin_password
    PROM_ADMIN_PASSWORD           = local.prom_admin_password
    PROM_REPLICAS_NUMBER          = var.prom_replicas_number
    PROM_STORAGE_RESOURCE_REQUEST = var.prom_storage_resource_request
    PROM_STORAGE_CLASS_NAME       = var.prom_storage_class_name
    PROM_RETENTION                = var.prom_retention
    MONITORING_NAMESPACE          = var.namespace

    PROM_CPU_REQUEST    = var.prom_cpu_mem_request["cpu"]
    PROM_MEMORY_REQUEST = var.prom_cpu_mem_request["memory"]
    PROM_CPU_LIMIT      = var.prom_cpu_mem_limits["cpu"]
    PROM_MEMORY_LIMIT   = var.prom_cpu_mem_limits["memory"]
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


resource "random_password" "prom_admin_password" {
  count   = var.prom_admin_password == "" ? 1 : 0
  length  = 30
  special = false
}


# Secret for Redis datasource
resource "kubernetes_secret" "prom_redis_datasource" {
  metadata {
    name      = "${var.project_name}-prom-redis-datasource"
    namespace = var.namespace
  }

  data = {
    password = local.redis_admin_password
  }

  type = "Opaque"
}