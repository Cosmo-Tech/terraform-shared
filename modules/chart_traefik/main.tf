
data "template_file" "traefik_values_static" {
  template = file("${path.module}/values.yaml")
  vars = {
    platform_lb_ip = var.platform_lb_ip
  }
}

locals {
  traefik_values_dynamic = yamlencode({
    service = {
      annotations = var.lb_annotations
    }
  })
}

data "kubernetes_secret" "monitoring_cert" {
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

  type = data.kubernetes_secret.monitoring_cert.type

  data = data.kubernetes_secret.monitoring_cert.data
}

resource "helm_release" "traefik_ingress" {
  name             = "traefik"
  repository       = var.helm_repo
  chart            = var.helm_chart
  version          = var.helm_chart_version
  namespace        = var.namespace
  create_namespace = false

  values = [data.template_file.traefik_values_static.rendered, local.traefik_values_dynamic]
}