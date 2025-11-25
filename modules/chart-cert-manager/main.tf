terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1.3"
    }
  }
}


resource "time_sleep" "wait_certmanager_crds" {
  create_duration = "60s"

  depends_on = [
    helm_release.cert_manager
  ]
}


data "template_file" "cert_values" {
  template = file("${path.module}/values.yaml")
  vars = {
    service_annotations = yamlencode(var.service_annotations)
  }
}


data "template_file" "clusterissuer_prod" {
  template = file("${path.module}/kube-objects/clusterissuer.yaml")
  vars = {
    certificate_email = var.certificate_email
  }
}


data "template_file" "certificate" {
  template = file("${path.module}/kube-objects/certificate.yaml")
  vars = {
    certificate_email = var.certificate_email
    cluster_domain    = var.cluster_domain
  }
}

# 1. CERT-MANAGER
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.11.0"
  namespace        = "cert-manager"
  create_namespace = true

  values = [
    data.template_file.cert_values.rendered
  ]
}

# 2. PROD ISSUER
resource "kubectl_manifest" "letsencrypt_prod" {
  yaml_body = data.template_file.clusterissuer_prod.rendered

  depends_on = [
    helm_release.cert_manager
  ]
}

resource "kubectl_manifest" "certificate" {
  yaml_body = data.template_file.certificate.rendered

  depends_on = [
    kubectl_manifest.letsencrypt_prod
  ]
}