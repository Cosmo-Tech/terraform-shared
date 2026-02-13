locals {
  # superset_secret_name    = "superset"
  superset_configmap_name = "superset-config-map"

  chart_values = {
    NAMESPACE      = var.namespace
    CLUSTER_DOMAIN = var.cluster_domain
    # SECRET_NAME    = local.superset_secret_name
    CONFIGMAP_NAME = local.superset_configmap_name
    # SUPERSET_SECRET_KEY = random_password.superset_secret_key.result
  }
}


# resource "random_password" "admin" {
#   length  = 40
#   special = false
# }

# # resource "random_password" "redis" {
# #   length  = 40
# #   special = false
# # }


# resource "random_password" "superset_secret_key" {
#   length  = 40
#   special = false
# }


# resource "kubernetes_secret" "superset_config" {
#   metadata {
#     name      = local.superset_secret_name
#     namespace = var.namespace
#   }

#   data = {
#     superset-admin-user = "admin"
#     superset-password   = random_password.admin.result
#     superset-secret-key = random_password.superset_secret_key.result
#     # redis-password      = random_password.redis.result
#   }

#   type = "Opaque"
# }



resource "kubernetes_config_map" "superset_config_map" {
  metadata {
    name      = local.superset_configmap_name
    namespace = var.namespace
  }

  data = {
    "superset_config.py" = templatefile("${path.module}/kube_objects/superset_config.py", local.chart_values)
  }
}


resource "helm_release" "superset" {
  name       = "superset"
  repository = var.helm_repo
  chart      = var.helm_chart
  version    = var.helm_chart_version
  namespace  = var.namespace

  values = [
    templatefile("${path.module}/values.yaml", local.chart_values)
  ]

  depends_on = [
    # kubernetes_secret.superset_config,
    kubernetes_config_map.superset_config_map
  ]
}
