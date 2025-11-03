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