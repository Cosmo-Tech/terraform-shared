# TEMPLATE RENDERING
data "template_file" "nginx_values" {
  template = file("${path.root}/helm-templates/nginx/nginx-values.yaml")
  vars = {
    sa_email       = var.sa_email
    platform_lb_ip = var.platform_lb_ip
  }
}

resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.12.3"
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [data.template_file.nginx_values.rendered]
}