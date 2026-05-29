locals {
  chart_values_file = templatefile("${path.module}/values.yaml", local.chart_values)
  chart_values = {
    PLATFORM_LB_IP             = var.platform_lb_ip
    IMAGE_REGISTRY             = var.image_registry
    IMAGE_REGISTRY_AUTH_SECRET = var.image_registry_auth_secret
    TRAEFIK_IMAGE_REPOSITORY   = var.traefik_image_repository
    TRAEFIK_IMAGE_TAG          = var.traefik_image_tag
  }

  chart_values_dynamic = yamlencode({
    service = {
      annotations = var.lb_annotations
    }
  })
}


data "kubernetes_secret" "certificate" {
  metadata {
    name      = "letsencrypt-prod"
    namespace = "cert-manager"
  }
}

resource "kubernetes_secret" "certificate" {
  metadata {
    name      = "letsencrypt-prod"
    namespace = var.namespace
  }

  type = data.kubernetes_secret.certificate.type
  data = data.kubernetes_secret.certificate.data
}


resource "helm_release" "traefik" {
  namespace  = var.namespace
  name       = var.chart_release
  repository = var.chart_repository
  chart      = var.chart_name
  version    = var.chart_tag

  values = [
    local.chart_values_file,
    local.chart_values_dynamic
  ]

  force_update  = true
  recreate_pods = true

  lifecycle {
    replace_triggered_by = [
      terraform_data.helm_release_trigger,
    ]
  }
}

resource "terraform_data" "helm_release_trigger" {
  input = {
    version     = var.chart_tag,
    values      = local.chart_values_file
    values_sha1 = sha1(local.chart_values_file)
  }
}
