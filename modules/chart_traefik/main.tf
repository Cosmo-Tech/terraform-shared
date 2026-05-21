locals {
  traefik_values_dynamic = yamlencode({
    service = {
      annotations = var.lb_annotations
    }
  })
}


data "template_file" "traefik_values_static" {
  template = file("${path.module}/values.yaml")
  vars = {
    platform_lb_ip = var.platform_lb_ip
  }
}

data "kubernetes_secret" "certificate" {
  metadata {
    name      = "letsencrypt-prod"
    namespace = "cert-manager"
  }
}

resource "kubernetes_secret" "traefik_cert" {
  metadata {
    name      = "letsencrypt-prod"
    namespace = var.namespace
  }

  type = data.kubernetes_secret.certificate.type

  data = data.kubernetes_secret.certificate.data
}

resource "helm_release" "traefik_ingress" {
  namespace        = var.namespace
  name             = var.chart_release
  repository       = var.chart_repository
  chart            = var.chart_name
  version          = var.chart_tag
  create_namespace = false

  values = [
    data.template_file.traefik_values_static.rendered,
    local.traefik_values_dynamic
  ]
}