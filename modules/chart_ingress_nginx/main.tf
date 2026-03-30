locals {
  nginx_values = templatefile("${path.module}/values.yaml", {
    service_annotations = yamlencode(var.service_annotations)
    lb_annotations      = yamlencode(var.lb_annotations)
    platform_lb_ip      = var.platform_lb_ip
  })
}

resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.12.3"
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [local.nginx_values]
}