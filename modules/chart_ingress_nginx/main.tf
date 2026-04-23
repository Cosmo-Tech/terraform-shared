
data "template_file" "nginx_values_static" {
  template = file("${path.module}/values.yaml")
  vars = {
    platform_lb_ip = var.platform_lb_ip
  }
}

locals {
  nginx_values_dynamic = yamlencode({
    controller = {
      service = {
        annotations = var.lb_annotations
      }
      serviceAccount = {
        annotations = var.service_annotations
      }
    }
  })
}

resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.12.3"
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [data.template_file.nginx_values_static.rendered, local.nginx_values_dynamic]
}