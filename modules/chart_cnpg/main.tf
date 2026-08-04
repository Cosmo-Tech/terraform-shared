locals {
  chart_values = {
    IMAGE_REGISTRY    = var.image_registry
    IMAGE_REPOSITORY  = var.image_repository
    IMAGE_TAG         = var.image_tag
    IMAGE_PULL_SECRET = var.image_pull_secret
  }

  chart_values_file = templatefile("${path.module}/values.yaml", local.chart_values)
}

resource "helm_release" "cnpg" {
  #   name       = var.chart_cnpg_release
  name      = "cnpg"
  namespace = var.namespace
  chart     = "oci://cgr.dev/cosmotech/charts/cloudnative-pg@sha256:0668abacde44373ba7c0ad6cd450570d8a741abf1adfbca3b066c4e54b67a067"
  #   repository = var.chart_cnpg_repository
  #   chart      = var.chart_cnpg_name
  #   version    = var.chart_cnpg_tag

  create_namespace = false

  wait          = false
  wait_for_jobs = false

  values = [
    local.chart_values_file
  ]

  force_update  = true
  recreate_pods = true
}