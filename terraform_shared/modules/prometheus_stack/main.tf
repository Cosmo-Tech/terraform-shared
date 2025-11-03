locals {
  redis_admin_password = var.redis_admin_password != "" ? var.redis_admin_password : (length(random_password.redis_admin_password) > 0 ? random_password.redis_admin_password[0].result : "")
  prom_admin_password  = var.prom_admin_password != "" ? var.prom_admin_password : (length(random_password.prom_admin_password) > 0 ? random_password.prom_admin_password[0].result : "")

  prometheus_values = {
    COSMOTECH_API_DNS_NAME        = var.api_dns_name
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

# Helm release for Prometheus stack
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
    templatefile("${path.root}/helm-templates/prometheus_stack/values.yaml", local.prometheus_values)
  ]
}


