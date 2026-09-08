locals {
  chart_values_file = templatefile("${path.module}/templates/values.yaml", local.chart_values)
  chart_values = {
    IMAGE_REGISTRY             = var.image_registry
    IMAGE_REPOSITORY           = var.image_repository
    IMAGE_TAG                  = var.image_tag
    IMAGE_REGISTRY_AUTH_SECRET = var.image_registry_auth_secret
  }
}

resource "helm_release" "cnpg" {
  name       = "cnpg"
  namespace  = var.namespace
  repository = var.chart_cnpg_repository
  chart      = var.chart_cnpg_name
  version    = var.chart_cnpg_tag

  create_namespace = false

  wait          = false
  wait_for_jobs = false

  values = [
    local.chart_values_file
  ]

  force_update  = true
  recreate_pods = true
}